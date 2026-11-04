package dev.rgal.brackety.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.endsWith;
import static org.hamcrest.Matchers.matchesPattern;
import static org.mockito.Mockito.doReturn;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.auth.account.AccountRepository;
import jakarta.servlet.http.Cookie;
import java.time.Duration;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

class AuthControllerTest extends AuthIntegrationTest {

    private static final String REGISTER_JSON = """
            {"email":"%s","password":"%s","birthDate":"%s","profile":"HELPER",
             "acceptedTermsVersion":"2026-11-04","acceptedPrivacyVersion":"2026-11-04","locale":"es"}""";
    private static final String ORGANIZER = """
            "organization":{"name":"Club Ficticio","taxId":"G12345674"},"representativeDeclaration":true""";

    @Autowired
    MockMvc mvc;

    @MockitoSpyBean
    AccountRepository accounts;

    @Test
    void registerAndDuplicateGetTheSameEmptyAccepted() throws Exception {
        var body = REGISTER_JSON.formatted("ana@example.test", PASSWORD, "1990-05-20");

        var first = register(body).andExpect(status().isAccepted()).andReturn().getResponse();
        var second = register(body).andExpect(status().isAccepted()).andReturn().getResponse();

        assertThat(first.getContentAsString()).isEmpty();
        assertThat(second.getContentAsString()).isEqualTo(first.getContentAsString());
        assertThat(count("account")).isOne();
    }

    @Test
    void concurrentDuplicateRegistrationIsStillAccepted() throws Exception {
        var body = REGISTER_JSON.formatted("ana@example.test", PASSWORD, "1990-05-20");
        register(body).andExpect(status().isAccepted());
        doReturn(Optional.empty()).when(accounts).lockByEmail("ana@example.test");

        register(body).andExpect(status().isAccepted());

        assertThat(count("account")).isOne();
    }

    @Test
    void rejectsAShortPassword() throws Exception {
        register(REGISTER_JSON.formatted("ana@example.test", "123456789", "1990-05-20"))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON));
        assertThat(count("account")).isZero();
    }

    @Test
    void rejectsUnder14() throws Exception {
        register(REGISTER_JSON.formatted("kid@example.test", PASSWORD, "2013-03-11"))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON));
    }

    @Test
    void registersAnOrganizerWithItsOrganizationAndDeclarationInsteadOfABirthDate() throws Exception {
        register(json(
                        "CLUB",
                        "\"organization\":{\"name\":\"  Club Ficticio  \",\"taxId\":\"g-1234.567 4\"},"
                                + "\"representativeDeclaration\":true"))
                .andExpect(status().isAccepted());

        assertThat(count("account where birth_date is null")).isOne();
        assertThat(count("profile where type = 'CLUB' and organization_name = 'Club Ficticio'"
                        + " and tax_id = 'G12345674' and not validated"))
                .isOne();
        assertThat(count("consent where document = 'ORGANIZER_DECLARATION' and version = '2026-11-04'"))
                .isOne();
    }

    @Test
    void anOrganizerGivesNoBirthDateButTheOrganizationAndTheDeclaration() throws Exception {
        var organization = "\"organization\":{\"name\":\"Club Ficticio\",\"taxId\":\"G12345674\"}";
        for (var fields : new String[] {
            ORGANIZER + ",\"birthDate\":\"1990-05-20\"",
            "\"representativeDeclaration\":true",
            organization,
            organization + ",\"representativeDeclaration\":false",
            "\"organization\":{\"name\":\" C \",\"taxId\":\"G12345674\"},\"representativeDeclaration\":true",
            "\"organization\":{\"name\":\"Club Ficticio\"},\"representativeDeclaration\":true"
        }) {
            register(json("EXTERNAL_ENTITY", fields))
                    .andExpect(status().isBadRequest())
                    .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                    .andExpect(jsonPath("$.code").doesNotExist());
        }
        assertThat(count("account")).isZero();
    }

    @Test
    void anyoneElseGivesTheBirthDateAndNoOrganization() throws Exception {
        for (var fields : new String[] {
            "\"birthDate\":\"1990-05-20\"," + ORGANIZER,
            "\"birthDate\":\"1990-05-20\",\"representativeDeclaration\":true",
            "\"representativeDeclaration\":true"
        }) {
            register(json("HELPER", fields)).andExpect(status().isBadRequest());
        }
        assertThat(count("account")).isZero();
    }

    @Test
    void anInvalidCifIsABadRequestWithItsCode() throws Exception {
        register(json("CLUB", ORGANIZER.replace("G12345674", "G12345675")))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.code").value("INVALID_TAX_ID"));
        assertThat(count("account")).isZero();
    }

    @Test
    void anOutdatedLegalVersionIsA409ProblemWithItsCode() throws Exception {
        var body = REGISTER_JSON.formatted("ana@example.test", PASSWORD, "1990-05-20");
        for (var field : new String[] {"acceptedTermsVersion", "acceptedPrivacyVersion"}) {
            register(body.replace(
                            "\"%s\":\"2026-11-04\"".formatted(field), "\"%s\":\"2026-11-draft\"".formatted(field)))
                    .andExpect(status().isConflict())
                    .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                    .andExpect(jsonPath("$.code").value("LEGAL_VERSION_OUTDATED"));
        }
        assertThat(count("account")).isZero();
    }

    @Test
    void failedLoginIsAGenericProblem() throws Exception {
        login(null, "nobody@example.test")
                .andExpect(status().isUnauthorized())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.detail").value("Invalid email or password."));
    }

    @Test
    void lockedLoginIsA429ProblemWithTheLockId() throws Exception {
        for (int i = 0; i < 5; i++) {
            login(null, "nobody@example.test").andExpect(status().isUnauthorized());
        }

        login(null, "nobody@example.test")
                .andExpect(status().isTooManyRequests())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.lockId").value(matchesPattern("L-[2-9A-HJKMNP-Z]{6}")));
    }

    @Test
    void webGetsTheRefreshTokenOnlyInAStrictHttpOnlyCookie() throws Exception {
        registerAna();

        var response = login("web", "ana@example.test")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.expiresIn").value(900))
                .andExpect(jsonPath("$.refreshToken").doesNotExist())
                .andReturn()
                .getResponse();

        assertThat(response.getHeader(HttpHeaders.SET_COOKIE))
                .startsWith(AuthController.REFRESH_COOKIE + "=")
                .contains("Path=/api/v1/auth", "Max-Age=2592000", "Secure", "HttpOnly", "SameSite=Strict");
    }

    @Test
    void androidGetsTheRefreshTokenInTheBody() throws Exception {
        registerAna();

        login(null, "ana@example.test")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.refreshToken").isNotEmpty())
                .andExpect(header().doesNotExist(HttpHeaders.SET_COOKIE));
    }

    @Test
    void webRefreshesWithTheCookieAndGetsANewOne() throws Exception {
        registerAna();
        var cookie =
                login("web", "ana@example.test").andReturn().getResponse().getCookie(AuthController.REFRESH_COOKIE);

        var renewed = mvc.perform(post("/api/v1/auth/refresh")
                        .header(AuthController.CLIENT_HEADER, "web")
                        .cookie(cookie))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.refreshToken").doesNotExist())
                .andReturn()
                .getResponse()
                .getCookie(AuthController.REFRESH_COOKIE);

        assertThat(renewed.getValue()).isNotBlank().isNotEqualTo(cookie.getValue());
    }

    @Test
    void aCookieRefreshNeverReturnsTheTokenInTheBody() throws Exception {
        registerAna();
        var cookie =
                login("web", "ana@example.test").andReturn().getResponse().getCookie(AuthController.REFRESH_COOKIE);

        mvc.perform(post("/api/v1/auth/refresh").cookie(cookie))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.refreshToken").doesNotExist())
                .andExpect(header().exists(HttpHeaders.SET_COOKIE));
    }

    @Test
    void androidRefreshesWithTheBody() throws Exception {
        registerAna();
        var refresh = refreshTokenOf(login(null, "ana@example.test"));

        mvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"%s\"}".formatted(refresh)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.refreshToken").isNotEmpty());
    }

    @Test
    void reusedRefreshIsUnauthorized() throws Exception {
        registerAna();
        var refresh = refreshTokenOf(login(null, "ana@example.test"));
        var body = "{\"refreshToken\":\"%s\"}".formatted(refresh);
        mvc.perform(post("/api/v1/auth/refresh")
                .contentType(MediaType.APPLICATION_JSON)
                .content(body));

        mvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void logoutClearsTheCookieAndRevokesTheSession() throws Exception {
        registerAna();
        var cookie =
                login("web", "ana@example.test").andReturn().getResponse().getCookie(AuthController.REFRESH_COOKIE);

        var cleared = mvc.perform(post("/api/v1/auth/logout").cookie(cookie))
                .andExpect(status().isNoContent())
                .andReturn()
                .getResponse()
                .getHeader(HttpHeaders.SET_COOKIE);

        assertThat(cleared).startsWith(AuthController.REFRESH_COOKIE + "=;").contains("Max-Age=0", "Path=/api/v1/auth");
        mvc.perform(post("/api/v1/auth/refresh").cookie(new Cookie(AuthController.REFRESH_COOKIE, cookie.getValue())))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void protectedEndpointNeedsAValidAccessToken() throws Exception {
        registerAna();
        var accessToken = JsonPath.<String>read(
                login(null, "ana@example.test").andReturn().getResponse().getContentAsString(), "$.accessToken");

        mvc.perform(get("/api/v1/test/whoami"))
                .andExpect(status().isUnauthorized())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(header().exists(HttpHeaders.WWW_AUTHENTICATE));
        mvc.perform(get("/api/v1/test/whoami").header(HttpHeaders.AUTHORIZATION, "Bearer not-a-jwt"))
                .andExpect(status().isUnauthorized())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON));
        mvc.perform(get("/api/v1/test/whoami").header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken))
                .andExpect(status().isOk())
                .andExpect(content().string(endsWith("[HELPER]")));

        clock.advance(Duration.ofMinutes(15).plusSeconds(1));
        mvc.perform(get("/api/v1/test/whoami").header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void loginTellsWhetherTheEmailIsVerified() throws Exception {
        registerAna();

        login(null, "ana@example.test").andExpect(jsonPath("$.emailVerified").value(false));
    }

    @Test
    void verifiedOnlyEndpointsNeedAVerifiedEmail() throws Exception {
        registerAna();
        var login = login(null, "ana@example.test").andReturn().getResponse().getContentAsString();

        mvc.perform(get("/api/v1/test/verified-only")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + JsonPath.read(login, "$.accessToken")))
                .andExpect(status().isForbidden())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON));

        postJson(
                        "/api/v1/auth/email/verify",
                        "{\"token\":\"%s\"}".formatted(tokenIn(emails.sent().getFirst())))
                .andExpect(status().isNoContent());
        var refreshed = postJson(
                        "/api/v1/auth/refresh",
                        "{\"refreshToken\":\"%s\"}".formatted(JsonPath.<String>read(login, "$.refreshToken")))
                .andExpect(jsonPath("$.emailVerified").value(true))
                .andReturn()
                .getResponse()
                .getContentAsString();

        mvc.perform(get("/api/v1/test/verified-only")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + JsonPath.read(refreshed, "$.accessToken")))
                .andExpect(status().isOk());
    }

    @Test
    void anInvalidLinkIsABadRequestProblem() throws Exception {
        postJson("/api/v1/auth/email/verify", "{\"token\":\"not-a-token\"}")
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.detail").value("This link is invalid or has expired."));
    }

    @Test
    void resendAndForgotAnswerTheSameEmptyAcceptedForAnyEmail() throws Exception {
        registerAna();

        for (var path : new String[] {"/api/v1/auth/email/resend", "/api/v1/auth/password/forgot"}) {
            for (var email : new String[] {"ana@example.test", "nobody@example.test"}) {
                var body = postJson(path, "{\"email\":\"%s\"}".formatted(email))
                        .andExpect(status().isAccepted())
                        .andReturn()
                        .getResponse()
                        .getContentAsString();
                assertThat(body).isEmpty();
            }
        }
    }

    @Test
    void resetRejectsAShortPassword() throws Exception {
        postJson("/api/v1/auth/password/reset", "{\"token\":\"x\",\"newPassword\":\"123456789\"}")
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON));
    }

    @Test
    void resetWithTheEmailedLinkChangesThePassword() throws Exception {
        registerAna();
        postJson("/api/v1/auth/password/forgot", "{\"email\":\"ana@example.test\"}");
        var token = tokenIn(emails.sent().getLast());

        postJson(
                        "/api/v1/auth/password/reset",
                        "{\"token\":\"%s\",\"newPassword\":\"a-brand-new-password\"}".formatted(token))
                .andExpect(status().isNoContent());

        login(null, "ana@example.test").andExpect(status().isUnauthorized());
    }

    @Test
    void checkingAResetLinkDoesNotUseIt() throws Exception {
        var token = emailedResetToken();

        checkResetLink(token).andExpect(status().isNoContent());
        checkResetLink(token).andExpect(status().isNoContent());

        postJson(
                        "/api/v1/auth/password/reset",
                        "{\"token\":\"%s\",\"newPassword\":\"a-brand-new-password\"}".formatted(token))
                .andExpect(status().isNoContent());
    }

    @Test
    void checkRejectsAUsedResetLink() throws Exception {
        var token = emailedResetToken();
        postJson(
                        "/api/v1/auth/password/reset",
                        "{\"token\":\"%s\",\"newPassword\":\"a-brand-new-password\"}".formatted(token))
                .andExpect(status().isNoContent());

        expectInvalidLink(checkResetLink(token));
    }

    @Test
    void checkRejectsAnExpiredResetLink() throws Exception {
        var token = emailedResetToken();
        clock.advance(Duration.ofHours(1));

        expectInvalidLink(checkResetLink(token));
    }

    @Test
    void checkRejectsAVerificationLinkAndAnUnknownOne() throws Exception {
        registerAna();
        var verifyToken = tokenIn(emails.sentTo("ana@example.test").getFirst());

        expectInvalidLink(checkResetLink(verifyToken));
        expectInvalidLink(checkResetLink("not-a-real-token"));
    }

    @Test
    void publicEndpointsStayOpen() throws Exception {
        mvc.perform(get("/api/v1/info")).andExpect(status().isOk());
        mvc.perform(get("/actuator/health")).andExpect(status().isOk());
    }

    private void registerAna() throws Exception {
        register(REGISTER_JSON.formatted("ana@example.test", PASSWORD, "1990-05-20"))
                .andExpect(status().isAccepted());
    }

    private String emailedResetToken() throws Exception {
        registerAna();
        postJson("/api/v1/auth/password/forgot", "{\"email\":\"ana@example.test\"}");
        return tokenIn(emails.sent().getLast());
    }

    private ResultActions checkResetLink(String token) throws Exception {
        return postJson("/api/v1/auth/password/reset/check", "{\"token\":\"%s\"}".formatted(token));
    }

    private static void expectInvalidLink(ResultActions result) throws Exception {
        result.andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.detail").value("This link is invalid or has expired."));
    }

    private ResultActions postJson(String path, String body) throws Exception {
        return mvc.perform(post(path).contentType(MediaType.APPLICATION_JSON).content(body));
    }

    private static String json(String profile, String fields) {
        return """
                {"email":"org@example.test","password":"%s","profile":"%s",%s,
                 "acceptedTermsVersion":"2026-11-04","acceptedPrivacyVersion":"2026-11-04","locale":"es"}""".formatted(PASSWORD, profile, fields);
    }

    private ResultActions register(String body) throws Exception {
        return mvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(body));
    }

    private ResultActions login(String client, String email) throws Exception {
        var request = post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"%s\",\"password\":\"%s\"}".formatted(email, PASSWORD));
        if (client != null) {
            request.header(AuthController.CLIENT_HEADER, client);
        }
        return mvc.perform(request);
    }

    private static String refreshTokenOf(ResultActions login) throws Exception {
        return JsonPath.read(login.andReturn().getResponse().getContentAsString(), "$.refreshToken");
    }
}
