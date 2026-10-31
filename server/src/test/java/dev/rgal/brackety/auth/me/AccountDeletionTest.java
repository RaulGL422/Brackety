package dev.rgal.brackety.auth.me;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.email.EmailToken;
import dev.rgal.brackety.auth.email.EmailTokens;
import dev.rgal.brackety.auth.google.FakeGoogle;
import dev.rgal.brackety.auth.google.GoogleSignInService;
import dev.rgal.brackety.auth.reauth.ReauthService;
import dev.rgal.brackety.auth.session.SessionService;
import dev.rgal.brackety.auth.session.SessionService.Session;
import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventRepository;
import java.time.Duration;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.transaction.support.TransactionOperations;

class AccountDeletionTest extends AuthIntegrationTest {

    private static final String ANA = "ana@example.test";
    private static final String BEA = "bea@example.test";
    private static final String IP = "203.0.113.10";

    @Autowired
    MockMvc mvc;

    @Autowired
    AuthService auth;

    @Autowired
    SessionService sessions;

    @Autowired
    FakeGoogle google;

    @Autowired
    EmailTokens emailTokens;

    @Autowired
    GoogleSignInService googleSignIn;

    @Autowired
    EventRepository events;

    @Autowired
    DeletedAccountPurge purge;

    @Autowired
    TransactionOperations transactions;

    @Test
    void deletingClosesEverySessionAndTellsTheDayItGoes() throws Exception {
        var session = account(ANA);
        var other = auth.login(ANA, PASSWORD, IP);
        emails.reset();

        deleteAccount(session)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.deletesOn").value("2027-04-09"));

        assertThat(count("account where status = 'DELETED' and deleted_at = '2027-03-10T09:00:00Z'"))
                .isOne();
        assertThatThrownBy(() -> sessions.refresh(session.refreshToken())).isInstanceOf(AuthException.class);
        assertThatThrownBy(() -> sessions.refresh(other.refreshToken())).isInstanceOf(AuthException.class);
        assertThat(emails.sentTo(ANA)).singleElement().satisfies(email -> {
            assertThat(email.subject()).isEqualTo("Tu cuenta de Brackety se va a borrar");
            assertThat(email.text()).contains("9 de abril de 2027");
        });
        mvc.perform(as(session, get("/api/v1/me"))).andExpect(status().isUnauthorized());
    }

    @Test
    void anEventOwnerCannotDeleteTheAccount() throws Exception {
        var session = account(ANA);
        events.save(Event.tambo(idOf(ANA), "Liga", LocalDate.of(2027, 4, 1), clock.instant()));
        emails.reset();

        deleteAccount(session)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("OWNS_EVENTS"));

        assertThat(count("account where status = 'ACTIVE' and deleted_at is null"))
                .isOne();
        assertThat(emails.sentTo(ANA)).isEmpty();
        mvc.perform(as(session, get("/api/v1/me"))).andExpect(status().isOk());
    }

    @Test
    void pastTheGraceTheAccountIsAsIfGoneUntilThePurgeRuns() throws Exception {
        linkGoogle(account(ANA), "sub-ana", ANA);
        deleteAccountOf(ANA);
        clock.advance(Duration.ofDays(30).minusMinutes(1));
        var restoreToken = restoreTokenOf(ANA);

        clock.advance(Duration.ofMinutes(1));

        login(ANA, PASSWORD)
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.detail").value("Invalid email or password."))
                .andExpect(jsonPath("$.restoreToken").doesNotExist());
        assertThatThrownBy(() -> googleSignIn.signIn(google.idToken("sub-ana", ANA), null))
                .isInstanceOfSatisfying(
                        AuthException.class,
                        e -> assertThat(e.getStatusCode().value()).isEqualTo(401));
        restore(restoreToken)
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.detail").value("Session expired. Log in again."));
        assertThat(count("account where status = 'DELETED'")).isOne();
    }

    @Test
    void theRightPasswordDuringTheGraceOffersTheRestoreAndRestoringSignsIn() throws Exception {
        deleteAccount(account(ANA));
        clock.advance(Duration.ofDays(29));

        var body = login(ANA, PASSWORD)
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("ACCOUNT_PENDING_DELETION"))
                .andExpect(jsonPath("$.deletesOn").value("2027-04-09"))
                .andExpect(jsonPath("$.accessToken").doesNotExist())
                .andReturn()
                .getResponse()
                .getContentAsString();
        String restoreToken = JsonPath.read(body, "$.restoreToken");

        restore(restoreToken)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty());

        assertThat(count("account where status = 'ACTIVE' and deleted_at is null"))
                .isOne();
        assertThat(auth.login(ANA, PASSWORD, IP).accessToken()).isNotBlank();
        restore(restoreToken).andExpect(status().isUnauthorized());
    }

    @Test
    void aWrongPasswordOnADeletedAccountIsTheGeneric401() throws Exception {
        deleteAccount(account(ANA));

        login(ANA, "wrong-password")
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.detail").value("Invalid email or password."))
                .andExpect(jsonPath("$.restoreToken").doesNotExist());
    }

    @Test
    void theRestoreTokenIsShortLivedAndNotAnAccessToken() throws Exception {
        deleteAccount(account(ANA));
        var token = restoreTokenOf(ANA);

        mvc.perform(get("/api/v1/me").header("Authorization", "Bearer " + token))
                .andExpect(status().isUnauthorized());
        clock.advance(Duration.ofMinutes(5).plusSeconds(1));
        restore(token).andExpect(status().isUnauthorized());
        restore("not-a-token").andExpect(status().isUnauthorized());
        assertThat(count("account where status = 'DELETED'")).isOne();
    }

    @Test
    void signingUpWithTheEmailTellsTheOwnerOnceAMinuteAndCreatesNothing() throws Exception {
        deleteAccount(account(ANA));
        emails.reset();

        auth.register(registration(ANA));
        auth.register(registration(ANA));

        assertThat(count("account")).isOne();
        assertThat(emails.sentTo(ANA))
                .singleElement()
                .satisfies(email ->
                        assertThat(email.subject()).isEqualTo("Tu cuenta de Brackety está pendiente de borrado"));
        clock.advance(Duration.ofSeconds(60));
        auth.register(registration(ANA));
        assertThat(emails.sentTo(ANA)).hasSize(2);
    }

    @Test
    void pastTheGraceSigningUpWithTheEmailTellsNobody() throws Exception {
        deleteAccount(account(ANA));
        clock.advance(Duration.ofDays(30));
        emails.reset();

        auth.register(registration(ANA));

        assertThat(emails.sentTo(ANA)).isEmpty();
        assertThat(count("account")).isOne();
    }

    @Test
    void thePurgeWaitsThirtyDays() {
        account(ANA);
        deleteAccountOf(ANA);

        clock.advance(Duration.ofDays(30).minusSeconds(1));
        purge.run();
        assertThat(count("account")).isOne();

        clock.advance(Duration.ofSeconds(1));
        purge.run();
        assertThat(count("account")).isZero();
    }

    @Test
    void anAccountThatCannotBePurgedDoesNotKeepTheOthers() {
        account(ANA);
        account(BEA);
        deleteAccountOf(ANA);
        clock.advance(Duration.ofSeconds(1));
        deleteAccountOf(BEA);
        // Only possible by hand: DELETE /me refuses an event owner.
        events.save(Event.tambo(idOf(ANA), "Liga", LocalDate.of(2027, 4, 1), clock.instant()));

        clock.advance(Duration.ofDays(30));
        purge.run();

        assertThat(jdbc.sql("select email from account").query(String.class).list())
                .containsExactly(ANA);
    }

    @Test
    void thePurgeTakesEverythingOfTheAccountAndNothingElse() throws Exception {
        linkGoogle(account(ANA), "sub-ana", ANA);
        linkGoogle(account(BEA), "sub-bea", BEA);
        transactions.executeWithoutResult(status -> {
            emailTokens.issue(idOf(ANA), EmailToken.Purpose.RESET_PASSWORD);
            emailTokens.issue(idOf(BEA), EmailToken.Purpose.RESET_PASSWORD);
        });
        login(ANA, "wrong-password");
        login(BEA, "wrong-password");
        var beaId = idOf(BEA);
        deleteAccountOf(ANA);

        clock.advance(Duration.ofDays(30));
        purge.run();

        assertThat(count("account")).isOne();
        for (var table :
                new String[] {"profile", "consent", "identity", "refresh_token", "email_token", "login_attempt"}) {
            assertThat(rows(table, "account_id is not null and account_id <> ?", beaId))
                    .as(table + " of the purged account")
                    .isZero();
            assertThat(rows(table, "account_id = ?", beaId))
                    .as(table + " of the other account")
                    .isPositive();
        }
    }

    private int rows(String table, String where, UUID accountId) {
        return jdbc.sql("select count(*) from " + table + " where " + where)
                .param(accountId)
                .query(Integer.class)
                .single();
    }

    private void linkGoogle(Session session, String subject, String email) throws Exception {
        mvc.perform(as(
                        session,
                        post("/api/v1/me/identities/google")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"idToken\":\"%s\"}".formatted(google.idToken(subject, email)))))
                .andExpect(status().isNoContent());
    }

    private void deleteAccountOf(String email) {
        try {
            deleteAccount(auth.login(email, PASSWORD, IP)).andExpect(status().isOk());
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    private ResultActions deleteAccount(Session session) throws Exception {
        return mvc.perform(
                as(session, delete("/api/v1/me")).header(ReauthService.HEADER, reauthWithPassword(mvc, session)));
    }

    private String restoreTokenOf(String email) {
        try {
            var body = login(email, PASSWORD).andReturn().getResponse().getContentAsString();
            return JsonPath.read(body, "$.restoreToken");
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    private ResultActions login(String email, String password) throws Exception {
        return mvc.perform(post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"%s\",\"password\":\"%s\"}".formatted(email, password)));
    }

    private ResultActions restore(String token) throws Exception {
        return mvc.perform(post("/api/v1/auth/restore")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"restoreToken\":\"%s\"}".formatted(token)));
    }

    private UUID idOf(String email) {
        return jdbc.sql("select id from account where email = ?")
                .param(email)
                .query(UUID.class)
                .single();
    }

    private Session account(String email) {
        auth.register(registration(email));
        jdbc.sql("update account set email_verified = true where email = ?")
                .param(email)
                .update();
        return auth.login(email, PASSWORD, IP);
    }
}
