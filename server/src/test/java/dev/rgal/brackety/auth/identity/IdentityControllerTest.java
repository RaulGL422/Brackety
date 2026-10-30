package dev.rgal.brackety.auth.identity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.IdentityRepository;
import dev.rgal.brackety.auth.email.PasswordResetService;
import dev.rgal.brackety.auth.google.FakeGoogle;
import dev.rgal.brackety.auth.google.GoogleSignInService;
import dev.rgal.brackety.auth.reauth.ReauthService;
import dev.rgal.brackety.auth.session.SessionService;
import dev.rgal.brackety.auth.session.SessionService.Session;
import java.time.Duration;
import java.time.LocalDate;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.transaction.support.TransactionOperations;

class IdentityControllerTest extends AuthIntegrationTest {

    private static final String ANA = "ana@example.test";
    private static final String BEA = "bea@example.test";
    private static final String IP = "203.0.113.10";

    @Autowired
    MockMvc mvc;

    @Autowired
    FakeGoogle google;

    @Autowired
    GoogleSignInService googleSignIn;

    @Autowired
    AuthService auth;

    @Autowired
    SessionService sessions;

    @Autowired
    PasswordResetService passwordReset;

    // Spies only for the race tests; the same pair as GoogleSignInControllerTest, so they share one context.
    @MockitoSpyBean
    AccountRepository accounts;

    @MockitoSpyBean
    IdentityRepository identities;

    @Autowired
    TransactionOperations transactions;

    @Test
    void everyEndpointNeedsAnAccessToken() throws Exception {
        for (var request : new MockHttpServletRequestBuilder[] {
            get("/api/v1/me/identities"),
            post("/api/v1/me/identities/google")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{\"idToken\":\"x\"}"),
            delete("/api/v1/me/identities/google"),
            delete("/api/v1/me/password")
        }) {
            mvc.perform(request)
                    .andExpect(status().isUnauthorized())
                    .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON));
        }
    }

    @Test
    void listsThePasswordAndEachLinkedIdentity() throws Exception {
        var session = passwordAccount(ANA);
        link(session, google.idToken("sub-ana", "ana.personal@example.test")).andExpect(status().isNoContent());

        mvc.perform(as(session, get("/api/v1/me/identities")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].method").value("PASSWORD"))
                .andExpect(jsonPath("$[0].email").doesNotExist())
                .andExpect(jsonPath("$[1].method").value("GOOGLE"))
                .andExpect(jsonPath("$[1].email").value("ana.personal@example.test"))
                .andExpect(jsonPath("$[1].linkedAt").value("2027-03-10T09:00:00Z"));
    }

    @Test
    void aGoogleOnlyAccountListsOnlyGoogle() throws Exception {
        var session = googleAccount(ANA, "sub-ana");

        mvc.perform(as(session, get("/api/v1/me/identities")))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].method").value("GOOGLE"));
    }

    @Test
    void linkingAGoogleAccountWithAnotherEmailLetsItSignInAndSendsANotice() throws Exception {
        var session = passwordAccount(ANA);
        emails.reset();

        link(session, google.idToken("sub-ana", "ana.personal@example.test")).andExpect(status().isNoContent());

        var signIn = googleSignIn.signIn(google.idToken("sub-ana", "ana.personal@example.test"), null);
        assertThat(signIn.session()).isNotNull();
        assertThat(count("account")).isOne();
        assertThat(emails.sentTo(ANA))
                .singleElement()
                .satisfies(email ->
                        assertThat(email.subject()).isEqualTo("Has vinculado una cuenta de Google a Brackety"));
    }

    @Test
    void linkingAGoogleAccountWithTheSameEmailVerifiesTheAccountSoItIsNotPurged() throws Exception {
        var session = unverifiedAccount(ANA);

        link(session, google.idToken("sub-ana", "ANA@example.test")).andExpect(status().isNoContent());

        assertThat(count("account where email_verified")).isOne();
        purgeUnverifiedAfterSevenDays();
        assertThat(count("account")).isOne();
    }

    @Test
    void anUnverifiedAccountCannotLinkAGoogleAccountWithAnotherEmail() throws Exception {
        var session = unverifiedAccount(ANA);

        link(session, google.idToken("sub-ana", "ana.personal@example.test"))
                .andExpect(status().isForbidden())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.code").value("EMAIL_NOT_VERIFIED"));

        assertThat(count("identity")).isZero();
        assertThat(count("account where email_verified")).isZero();
        purgeUnverifiedAfterSevenDays();
        assertThat(count("account")).isZero();
    }

    // Pre-hijacking: someone signs up with Ana's email and tries to plant their own Google account before
    // Ana takes the account back with a password reset.
    @Test
    void aForeignGoogleAccountCannotBePlantedBeforeTheOwnerVerifies() throws Exception {
        var attacker = unverifiedAccount(ANA);
        var attackerGoogle = google.idToken("sub-attacker", "attacker@example.test");
        link(attacker, attackerGoogle).andExpect(status().isForbidden());

        passwordReset.forgot(ANA);
        passwordReset.reset(tokenIn(emails.sentTo(ANA).getLast()), "the-owner-password");

        mvc.perform(post("/api/v1/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"idToken\":\"%s\"}".formatted(attackerGoogle)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("REGISTRATION_REQUIRED"))
                .andExpect(jsonPath("$.email").value("attacker@example.test"))
                .andExpect(jsonPath("$.accessToken").doesNotExist());
        assertThat(count("identity")).isZero();
    }

    @Test
    void aConcurrentLinkOfTheSameGoogleAccountIsIdentityInUse() throws Exception {
        googleAccount(BEA, "sub-bea");
        var session = passwordAccount(ANA);
        emails.reset();
        // As if Bea's link had not committed yet when this one looked: the insert clashes.
        doAnswer(firstCallReturns(Optional.empty(), identities))
                .when(identities)
                .findByProviderAndSubject(any(), any());

        link(session, google.idToken("sub-bea", BEA))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("IDENTITY_IN_USE"));
        assertThat(count("identity")).isOne();
        assertThat(emails.sentTo(ANA)).isEmpty();
    }

    @Test
    void linkingTheSameGoogleAccountAgainChangesNothing() throws Exception {
        var session = passwordAccount(ANA);
        var token = google.idToken("sub-ana", ANA);
        link(session, token);
        emails.reset();

        link(session, token).andExpect(status().isNoContent());

        assertThat(count("identity")).isOne();
        assertThat(emails.sent()).isEmpty();
    }

    @Test
    void aGoogleAccountLinkedElsewhereIsIdentityInUse() throws Exception {
        googleAccount(BEA, "sub-bea");
        var session = passwordAccount(ANA);

        link(session, google.idToken("sub-bea", BEA))
                .andExpect(status().isConflict())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.code").value("IDENTITY_IN_USE"));
        assertThat(count("identity")).isOne();
    }

    @Test
    void aSecondGoogleAccountIsRejected() throws Exception {
        var session = passwordAccount(ANA);
        link(session, google.idToken("sub-ana", ANA));

        link(session, google.idToken("sub-ana-2", ANA))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("PROVIDER_ALREADY_LINKED"));
    }

    @Test
    void linkingNeedsAValidGoogleToken() throws Exception {
        var session = passwordAccount(ANA);

        link(session, "not-a-google-token").andExpect(status().isUnauthorized());
        assertThat(count("identity")).isZero();
    }

    @Test
    void unlinkingTheOnlySignInMethodIsRefused() throws Exception {
        var session = googleAccount(ANA, "sub-ana");
        var reauth = reauthWithGoogle(mvc, session, google.idToken("sub-ana", ANA));

        mvc.perform(as(session, delete("/api/v1/me/identities/google")).header(ReauthService.HEADER, reauth))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("LAST_SIGN_IN_METHOD"));
        assertThat(count("identity")).isOne();
    }

    @Test
    void unlinkingGoogleWithAPasswordWorksAndSendsANotice() throws Exception {
        var session = passwordAccount(ANA);
        link(session, google.idToken("sub-ana", ANA));
        emails.reset();

        mvc.perform(as(session, delete("/api/v1/me/identities/google"))
                        .header(ReauthService.HEADER, reauthWithPassword(mvc, session)))
                .andExpect(status().isNoContent());

        assertThat(count("identity")).isZero();
        assertThat(emails.sentTo(ANA))
                .singleElement()
                .satisfies(email ->
                        assertThat(email.subject()).isEqualTo("Has desvinculado tu cuenta de Google de Brackety"));
    }

    @Test
    void removingThePasswordWithoutAnotherMethodIsRefused() throws Exception {
        var session = passwordAccount(ANA);

        mvc.perform(as(session, delete("/api/v1/me/password"))
                        .header(ReauthService.HEADER, reauthWithPassword(mvc, session)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("LAST_SIGN_IN_METHOD"));
        assertThat(count("account where password_hash is not null")).isOne();
    }

    @Test
    void removingThePasswordClosesEverySessionAndSendsANotice() throws Exception {
        var session = passwordAccount(ANA);
        link(session, google.idToken("sub-ana", ANA));
        var reauth = reauthWithPassword(mvc, session);
        emails.reset();

        mvc.perform(as(session, delete("/api/v1/me/password")).header(ReauthService.HEADER, reauth))
                .andExpect(status().isNoContent());

        assertThat(count("account where password_hash is null")).isOne();
        assertThatThrownBy(() -> sessions.refresh(session.refreshToken())).isInstanceOf(AuthException.class);
        assertThat(emails.sentTo(ANA))
                .singleElement()
                .satisfies(email ->
                        assertThat(email.subject()).isEqualTo("Se ha quitado la contraseña de tu cuenta de Brackety"));
        assertThat(googleSignIn.signIn(google.idToken("sub-ana", ANA), null).session())
                .isNotNull();
    }

    @Test
    void passwordLoginOnAnAccountWithoutPasswordIsTheGeneric401AndCounts() {
        googleAccount(ANA, "sub-ana");

        assertThatThrownBy(() -> auth.login(ANA, PASSWORD, IP))
                .isInstanceOfSatisfying(
                        AuthException.class,
                        e -> assertThat(e.getBody().getDetail()).isEqualTo("Invalid email or password."));
        assertThat(count("login_attempt where failures = 1 and account_id is not null"))
                .isOne();
    }

    @Test
    void aGoogleOnlyAccountCanSetAPasswordThroughRecovery() {
        googleAccount(ANA, "sub-ana");

        passwordReset.forgot(ANA);
        passwordReset.reset(tokenIn(emails.sentTo(ANA).getLast()), "a-brand-new-password");

        assertThat(auth.login(ANA, "a-brand-new-password", IP).accessToken()).isNotBlank();
    }

    @Test
    void aDeletedAccountCannotChangeItsMethods() throws Exception {
        var session = passwordAccount(ANA);
        var reauth = reauthWithPassword(mvc, session);
        jdbc.sql("update account set status = 'DELETED', deleted_at = now()").update();

        mvc.perform(as(session, get("/api/v1/me/identities"))).andExpect(status().isUnauthorized());
        mvc.perform(as(session, delete("/api/v1/me/password")).header(ReauthService.HEADER, reauth))
                .andExpect(status().isUnauthorized());
    }

    // The query the daily purge runs (its class is internal to auth.email).
    private void purgeUnverifiedAfterSevenDays() {
        clock.advance(Duration.ofDays(7));
        transactions.executeWithoutResult(
                status -> accounts.deleteUnverified(clock.instant().minus(Duration.ofDays(7))));
    }

    private Session passwordAccount(String email) {
        auth.register(registration(email));
        jdbc.sql("update account set email_verified = true where email = ?")
                .param(email)
                .update();
        return auth.login(email, PASSWORD, IP);
    }

    private Session unverifiedAccount(String email) {
        auth.register(registration(email));
        return auth.login(email, PASSWORD, IP);
    }

    private Session googleAccount(String email, String subject) {
        return googleSignIn
                .signIn(google.idToken(subject, email), details(LocalDate.of(1990, 5, 20)))
                .session();
    }

    private ResultActions link(Session session, String idToken) throws Exception {
        return mvc.perform(as(
                session,
                post("/api/v1/me/identities/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"idToken\":\"%s\"}".formatted(idToken))));
    }
}
