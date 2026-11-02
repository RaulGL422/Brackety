package dev.rgal.brackety.auth.admin;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.tuple;
import static org.hamcrest.Matchers.matchesPattern;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.account.ProfileType;
import dev.rgal.brackety.auth.lockout.LoginAttempt;
import java.net.URI;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

class AdminApiTest extends AuthIntegrationTest {

    private static final String IP = "203.0.113.10";
    // The superadmin logs in from elsewhere, so the locks a test sets on IP do not get in its way.
    private static final String ADMIN_IP = "192.0.2.50";
    private static final String ANA = "ana@example.test";
    private static final String LOCKS = "/api/v1/admin/auth/locks";

    @Autowired
    MockMvc mvc;

    @Autowired
    AuthService auth;

    @Autowired
    FakeCloudflareAccess cloudflare;

    @Autowired
    AdminLockService locks;

    // --- Cloudflare Access

    @Test
    void withoutTheAccessAssertionEvenTheLoginIs403() throws Exception {
        mvc.perform(post("/api/v1/admin/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginJson(SUPERADMIN_EMAIL, PASSWORD)))
                .andExpect(status().isForbidden())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON));
        mvc.perform(get(LOCKS).header(HttpHeaders.AUTHORIZATION, "Bearer " + adminToken()))
                .andExpect(status().isForbidden());
        assertThat(count("admin_audit")).isOne();
    }

    @Test
    void aForgedAccessAssertionIs403() throws Exception {
        var forged = FakeCloudflareAccess.sign(cloudflare.claims().build(), FakeCloudflareAccess.newKey("forged"));

        mvc.perform(get(LOCKS)
                        .header(CloudflareAccess.HEADER, forged)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + adminToken()))
                .andExpect(status().isForbidden());
    }

    // Spellings of an admin path that must never get past Access: 403 there, or rejected (4xx) before.
    @ParameterizedTest
    @ValueSource(
            strings = {
                "/api/v1/admin/auth/locks/",
                "/api/v1/%61dmin/auth/locks",
                "/api/v1/admin",
                "/api/v1/admin//auth/locks",
                "/api/v1/admin;x=1/auth/locks"
            })
    void noSpellingOfAnAdminPathSkipsAccess(String path) throws Exception {
        auth.register(registration(ANA));
        var userToken = auth.login(ANA, PASSWORD, IP).accessToken();

        for (var token : List.of(adminToken(), userToken)) {
            var status = mvc.perform(get(URI.create(path)).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                    .andReturn()
                    .getResponse()
                    .getStatus();
            assertThat(status).as(path).isBetween(400, 499);
        }
    }

    @Test
    void theRestOfTheApiDoesNotAskForAccess() throws Exception {
        mvc.perform(get("/api/v1/info")).andExpect(status().isOk());
    }

    // --- Login

    @Test
    void theSuperadminLogsInForOneHourAndItIsAudited() throws Exception {
        adminLogin(SUPERADMIN_EMAIL, PASSWORD)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.expiresIn").value(3600))
                .andExpect(jsonPath("$.refreshToken").doesNotExist());

        assertThat(audit("ADMIN_LOGIN")).containsExactly("null");
    }

    @Test
    void theEmailIsComparedNormalised() throws Exception {
        adminLogin(" SuperAdmin@Example.test ", PASSWORD).andExpect(status().isOk());
    }

    @Test
    void aWrongPasswordOrAnotherEmailIsTheGeneric401() throws Exception {
        auth.register(registration(ANA));

        adminLogin(SUPERADMIN_EMAIL, "wrong-password")
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.detail").value("Invalid email or password."));
        // A user's own credentials do not open the superadmin API either.
        adminLogin(ANA, PASSWORD)
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.detail").value("Invalid email or password."));
        assertThat(count("admin_audit")).isZero();
    }

    @Test
    void fiveFailuresLockTheSuperadminLoginWithALockId() throws Exception {
        failAdminLogin(5);

        var body = adminLogin(SUPERADMIN_EMAIL, PASSWORD)
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.lockId").value(matchesPattern("L-[2-9A-HJKMNP-Z]{6}")))
                .andReturn()
                .getResponse()
                .getContentAsString();
        assertThat(emails.sent()).isEmpty();
        assertThat(locks.activeLocks()).singleElement().satisfies(lock -> {
            assertThat(lock.lockId()).isEqualTo(JsonPath.read(body, "$.lockId"));
            assertThat(lock.type()).isEqualTo(LoginAttempt.Kind.ADMIN);
            assertThat(lock.email()).isNull();
        });
    }

    @Test
    void failuresOnThePublicLoginWithTheSuperadminEmailDoNotLockTheSuperadmin() throws Exception {
        for (int i = 0; i < 5; i++) {
            loginFails(SUPERADMIN_EMAIL, "198.51.100." + i);
        }
        assertThatThrownBy(() -> auth.login(SUPERADMIN_EMAIL, PASSWORD, IP))
                .isInstanceOfSatisfying(
                        AuthException.class,
                        e -> assertThat(e.getStatusCode().value()).isEqualTo(429));

        assertThat(adminToken()).isNotBlank();
    }

    @Test
    void failuresOnTheSuperadminLoginDoNotLockThePublicLoginOfThatEmail() throws Exception {
        auth.register(registration(SUPERADMIN_EMAIL));

        failAdminLogin(5);

        assertThat(auth.login(SUPERADMIN_EMAIL, PASSWORD, IP).accessToken()).isNotBlank();
    }

    private void failAdminLogin(int times) throws Exception {
        for (int i = 0; i < times; i++) {
            adminLogin(SUPERADMIN_EMAIL, "wrong-password", "198.51.100." + i).andExpect(status().isUnauthorized());
        }
    }

    @Test
    void theAdminLoginCountsTowardsTheIpLockOfTheUserLogin() throws Exception {
        for (int i = 0; i < 29; i++) {
            loginFails("guess" + i + "@example.test", ADMIN_IP);
        }

        adminLogin(SUPERADMIN_EMAIL, "wrong-password").andExpect(status().isUnauthorized());

        assertThatThrownBy(() -> auth.login(ANA, PASSWORD, ADMIN_IP))
                .isInstanceOfSatisfying(
                        AuthException.class,
                        e -> assertThat(e.getStatusCode().value()).isEqualTo(429));
    }

    @Test
    void withoutCredentialsTheLoginIs503() {
        // The email alone is not enough: without the hash there is no superadmin.
        var unconfigured = new AdminAuthService(null, null, null, null, clock, SUPERADMIN_EMAIL, " ");

        assertThatThrownBy(() -> unconfigured.login(SUPERADMIN_EMAIL, PASSWORD, IP))
                .isInstanceOfSatisfying(
                        AuthException.class,
                        e -> assertThat(e.getStatusCode().value()).isEqualTo(503));
    }

    // --- Tokens of one API on the other

    @Test
    void theAdminTokenDoesNotOpenTheUserApi() throws Exception {
        mvc.perform(get("/api/v1/me").header(HttpHeaders.AUTHORIZATION, "Bearer " + adminToken()))
                .andExpect(status().isUnauthorized())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON));
    }

    @Test
    void aUserAccessTokenDoesNotOpenTheAdminApi() throws Exception {
        auth.register(registration(ANA));
        var session = auth.login(ANA, PASSWORD, IP);

        mvc.perform(withAccess(get(LOCKS)).header(HttpHeaders.AUTHORIZATION, "Bearer " + session.accessToken()))
                .andExpect(status().isUnauthorized());
        mvc.perform(withAccess(get(LOCKS))).andExpect(status().isUnauthorized());
    }

    @Test
    void theAdminTokenLastsOneHour() throws Exception {
        var token = adminToken();

        clock.advance(Duration.ofHours(1));
        mvc.perform(asAdmin(get(LOCKS), token)).andExpect(status().isOk());

        clock.advance(Duration.ofSeconds(1));
        mvc.perform(asAdmin(get(LOCKS), token)).andExpect(status().isUnauthorized());
    }

    // --- Locks

    @Test
    void listsActiveEmailAndIpLocks() throws Exception {
        auth.register(registration(ANA));
        var emailLock = lockEmail(ANA);
        var ipLock = lockIp("198.51.100.77");
        var unknownLock = lockEmail("nobody@example.test");

        var body = mvc.perform(asAdmin(get(LOCKS)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        List<Map<String, Object>> locks = JsonPath.read(body, "$");
        assertThat(locks)
                .extracting("lockId", "type", "email", "ip", "lockedUntil")
                .containsExactlyInAnyOrder(
                        tuple(emailLock, "EMAIL", ANA, null, "2027-03-10T09:15:00Z"),
                        tuple(ipLock, "IP", null, "198.51.100.77", "2027-03-10T09:15:00Z"),
                        tuple(unknownLock, "EMAIL", null, null, "2027-03-10T09:15:00Z"));

        clock.advance(Duration.ofMinutes(15));
        mvc.perform(asAdmin(get(LOCKS))).andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void revokingALockLetsTheUserTryAgainAndIsAudited() throws Exception {
        auth.register(registration(ANA));
        var lockId = lockEmail(ANA);

        mvc.perform(asAdmin(delete(LOCKS + "/" + lockId))).andExpect(status().isNoContent());

        assertThat(auth.login(ANA, PASSWORD, IP).accessToken()).isNotBlank();
        assertThat(audit("LOCK_REVOKED")).containsExactly(lockId);
        mvc.perform(asAdmin(delete(LOCKS + "/" + lockId))).andExpect(status().isNotFound());
    }

    @Test
    void revokingAnIpLockLetsThatIpTryAgain() throws Exception {
        auth.register(registration(ANA));
        var lockId = lockIp(IP);

        mvc.perform(asAdmin(delete(LOCKS + "/" + lockId))).andExpect(status().isNoContent());

        assertThat(auth.login(ANA, PASSWORD, IP).accessToken()).isNotBlank();
    }

    @Test
    void anUnknownOrExpiredLockIs404() throws Exception {
        var lockId = lockEmail(ANA);

        mvc.perform(asAdmin(delete(LOCKS + "/L-ZZZZZZ")))
                .andExpect(status().isNotFound())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON));
        clock.advance(Duration.ofMinutes(15));
        mvc.perform(asAdmin(delete(LOCKS + "/" + lockId))).andExpect(status().isNotFound());
        assertThat(audit("LOCK_REVOKED")).isEmpty();
    }

    // --- Organizers

    @Test
    void listsOrganizersOfActiveAccountsByValidation() throws Exception {
        var club = register("club@example.test", ProfileType.CLUB, "es");
        clock.advance(Duration.ofMinutes(1));
        var entity = register("entidad@example.test", ProfileType.EXTERNAL_ENTITY, "en");
        register("alumno@example.test", ProfileType.STUDENT, "es");
        var gone = register("borrado@example.test", ProfileType.CLUB, "es");
        jdbc.sql("update account set status = 'DELETED', deleted_at = now() where id = ?")
                .param(gone)
                .update();

        assertThat(organizers("?validated=false"))
                .extracting("accountId", "email", "profileType", "validated", "organizationName", "taxId", "createdAt")
                .containsExactly(
                        tuple(
                                club.toString(),
                                "club@example.test",
                                "CLUB",
                                false,
                                "Club Ficticio",
                                "G12345674",
                                "2027-03-10T09:00:00Z"),
                        tuple(
                                entity.toString(),
                                "entidad@example.test",
                                "EXTERNAL_ENTITY",
                                false,
                                "Club Ficticio",
                                "G12345674",
                                "2027-03-10T09:01:00Z"));
        assertThat(organizers("?validated=true")).isEmpty();

        validate(club).andExpect(status().isNoContent());

        assertThat(organizers("?validated=true")).extracting("accountId").containsExactly(club.toString());
        assertThat(organizers("")).hasSize(2);
    }

    @Test
    void validatingEmailsTheOrganizerInTheirLanguageOnceAndIsAudited() throws Exception {
        var club = register("club@example.test", ProfileType.CLUB, "es");
        var entity = register("entidad@example.test", ProfileType.EXTERNAL_ENTITY, "en");
        emails.reset();

        validate(club).andExpect(status().isNoContent());
        validate(entity).andExpect(status().isNoContent());
        validate(club).andExpect(status().isNoContent());

        assertThat(emails.sentTo("club@example.test"))
                .singleElement()
                .satisfies(e -> assertThat(e.subject()).isEqualTo("Tu perfil de club en Brackety está validado"));
        assertThat(emails.sentTo("entidad@example.test")).singleElement().satisfies(e -> {
            assertThat(e.subject()).isEqualTo("Your external entity profile on Brackety is validated");
            assertThat(e.text()).contains("You can now publish events");
        });
        assertThat(audit("ORGANIZER_VALIDATED")).containsExactlyInAnyOrder(club.toString(), entity.toString());
        assertThat(jdbc.sql("select count(*) from profile where validated")
                        .query(Integer.class)
                        .single())
                .isEqualTo(2);
    }

    @Test
    void validatingWhatIsNotAnActiveOrganizerIs404() throws Exception {
        var student = register("alumno@example.test", ProfileType.STUDENT, "es");
        var gone = register("borrado@example.test", ProfileType.CLUB, "es");
        jdbc.sql("update account set status = 'DELETED', deleted_at = now() where id = ?")
                .param(gone)
                .update();

        validate(UUID.randomUUID()).andExpect(status().isNotFound());
        validate(student).andExpect(status().isNotFound());
        validate(gone).andExpect(status().isNotFound());
        assertThat(audit("ORGANIZER_VALIDATED")).isEmpty();
        assertThat(jdbc.sql("select count(*) from profile where validated")
                        .query(Integer.class)
                        .single())
                .isZero();
    }

    // --- Helpers

    private ResultActions adminLogin(String email, String password) throws Exception {
        return adminLogin(email, password, ADMIN_IP);
    }

    private ResultActions adminLogin(String email, String password, String ip) throws Exception {
        return mvc.perform(withAccess(post("/api/v1/admin/auth/login"))
                .with(request -> {
                    request.setRemoteAddr(ip);
                    return request;
                })
                .contentType(MediaType.APPLICATION_JSON)
                .content(loginJson(email, password)));
    }

    private String adminToken() throws Exception {
        var body = adminLogin(SUPERADMIN_EMAIL, PASSWORD)
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }

    private MockHttpServletRequestBuilder withAccess(MockHttpServletRequestBuilder request) {
        return request.header(CloudflareAccess.HEADER, cloudflare.assertion());
    }

    private MockHttpServletRequestBuilder asAdmin(MockHttpServletRequestBuilder request) throws Exception {
        return asAdmin(request, adminToken());
    }

    private MockHttpServletRequestBuilder asAdmin(MockHttpServletRequestBuilder request, String token) {
        return withAccess(request).header(HttpHeaders.AUTHORIZATION, "Bearer " + token);
    }

    private List<Map<String, Object>> organizers(String query) throws Exception {
        var body = mvc.perform(asAdmin(get("/api/v1/admin/organizers" + query)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        return JsonPath.read(body, "$");
    }

    private ResultActions validate(UUID accountId) throws Exception {
        return mvc.perform(asAdmin(post("/api/v1/admin/organizers/" + accountId + "/validate")));
    }

    private UUID register(String email, ProfileType profile, String locale) {
        auth.register(registration(email, profile, locale));
        return jdbc.sql("select id from account where email = ?")
                .param(email)
                .query(UUID.class)
                .single();
    }

    private String lockEmail(String email) {
        for (int i = 0; i < 5; i++) {
            loginFails(email, "198.51.100." + i);
        }
        return lockIdOf(() -> auth.login(email, PASSWORD, "198.51.100.200"));
    }

    private String lockIp(String ip) {
        for (int i = 0; i < 30; i++) {
            loginFails("user" + i + "@example.test", ip);
        }
        return lockIdOf(() -> auth.login("someone@example.test", PASSWORD, ip));
    }

    private void loginFails(String email, String ip) {
        assertThatThrownBy(() -> auth.login(email, "wrong-password", ip)).isInstanceOf(AuthException.class);
    }

    private static String lockIdOf(Runnable lockedLogin) {
        try {
            lockedLogin.run();
        } catch (AuthException e) {
            assertThat(e.getStatusCode().value()).isEqualTo(429);
            return (String) e.getBody().getProperties().get("lockId");
        }
        throw new AssertionError("The login was not locked");
    }

    /** Targets audited for the action ("null" when it has none). */
    private List<String> audit(String action) {
        return jdbc.sql("select coalesce(target, 'null') from admin_audit where action = ?")
                .param(action)
                .query(String.class)
                .list();
    }

    private static String loginJson(String email, String password) {
        return "{\"email\":\"%s\",\"password\":\"%s\"}".formatted(email, password);
    }
}
