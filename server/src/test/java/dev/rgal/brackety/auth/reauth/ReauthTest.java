package dev.rgal.brackety.auth.reauth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.email.PasswordResetService;
import dev.rgal.brackety.auth.google.FakeGoogle;
import dev.rgal.brackety.auth.google.GoogleSignInService;
import dev.rgal.brackety.auth.session.SessionService.Session;
import java.time.Duration;
import java.time.LocalDate;
import java.util.Date;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

class ReauthTest extends AuthIntegrationTest {

    private static final String ANA = "ana@example.test";
    private static final String BEA = "bea@example.test";

    @Autowired
    MockMvc mvc;

    @Autowired
    AuthService auth;

    @Autowired
    GoogleSignInService googleSignIn;

    @Autowired
    FakeGoogle google;

    @Autowired
    PasswordResetService passwordReset;

    @Test
    void everyNewMeEndpointNeedsAnAccessToken() throws Exception {
        for (var request : new MockHttpServletRequestBuilder[] {
            get("/api/v1/me"),
            patch("/api/v1/me").contentType(MediaType.APPLICATION_JSON).content("{\"locale\":\"en\"}"),
            delete("/api/v1/me"),
            get("/api/v1/me/export"),
            post("/api/v1/me/reauth").contentType(MediaType.APPLICATION_JSON).content("{\"password\":\"x\"}"),
            post("/api/v1/me/email")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{\"newEmail\":\"n@example.test\"}"),
            post("/api/v1/me/profiles").contentType(MediaType.APPLICATION_JSON).content("{\"type\":\"HELPER\"}"),
            delete("/api/v1/me/profiles/HELPER")
        }) {
            mvc.perform(request)
                    .andExpect(status().isUnauthorized())
                    .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON));
        }
    }

    @Test
    void everySensitiveActionWithoutReauthIsRefused() throws Exception {
        var session = account(ANA);

        for (var request : sensitiveActions()) {
            mvc.perform(as(session, request))
                    .andExpect(status().isForbidden())
                    .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                    .andExpect(jsonPath("$.code").value("REAUTH_REQUIRED"));
        }
        assertThat(count("account where status = 'ACTIVE' and email = 'ana@example.test'"))
                .isOne();
    }

    @Test
    void thePasswordGivesAFiveMinuteTokenThatOpensTheSensitiveActions() throws Exception {
        var session = account(ANA);

        reauth(session, "{\"password\":\"%s\"}".formatted(PASSWORD))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.expiresIn").value(300));
        var token = reauthWithPassword(mvc, session);

        mvc.perform(as(session, get("/api/v1/me/export")).header(ReauthService.HEADER, token))
                .andExpect(status().isOk());
    }

    @Test
    void aWrongPasswordIsRefusedAndCountsForTheLoginLock() throws Exception {
        var session = account(ANA);

        for (int i = 0; i < 4; i++) {
            reauth(session, "{\"password\":\"wrong-password\"}")
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("REAUTH_FAILED"));
        }
        assertThat(count("login_attempt where failures = 4 and account_id is not null"))
                .isOne();
        reauth(session, "{\"password\":\"wrong-password\"}").andExpect(status().isForbidden());

        reauth(session, "{\"password\":\"%s\"}".formatted(PASSWORD))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.lockId").exists());
        mvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"%s\",\"password\":\"%s\"}".formatted(ANA, PASSWORD)))
                .andExpect(status().isTooManyRequests());
    }

    @Test
    void aLinkedGoogleAccountReauthenticatesButAnotherOneDoesNot() throws Exception {
        var session = googleSignIn
                .signIn(google.idToken("sub-ana", ANA), details(LocalDate.of(1990, 5, 20)))
                .session();
        googleSignIn.signIn(google.idToken("sub-bea", BEA), details(LocalDate.of(1990, 5, 20)));

        var token = reauthWithGoogle(mvc, session, google.idToken("sub-ana", ANA));
        mvc.perform(as(session, get("/api/v1/me/export")).header(ReauthService.HEADER, token))
                .andExpect(status().isOk());

        reauth(session, "{\"googleIdToken\":\"%s\"}".formatted(google.idToken("sub-bea", BEA)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("REAUTH_FAILED"));
        reauth(session, "{\"googleIdToken\":\"%s\"}".formatted(google.idToken("sub-unknown", ANA)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("REAUTH_FAILED"));
    }

    @Test
    void aBadGoogleTokenIsAFailedProofNotAClosedSession() throws Exception {
        var session = googleSignIn
                .signIn(google.idToken("sub-ana", ANA), details(LocalDate.of(1990, 5, 20)))
                .session();
        var expired = google.sign(google.claims("sub-ana", ANA)
                .expirationTime(Date.from(clock.instant().minusSeconds(120)))
                .build());

        for (var idToken : new String[] {"not-a-google-token", expired}) {
            reauth(session, "{\"googleIdToken\":\"%s\"}".formatted(idToken))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("REAUTH_FAILED"));
        }
    }

    @Test
    void aTokenIssuedBeforeAPasswordResetIsRefused() throws Exception {
        var session = account(ANA);
        var token = reauthWithPassword(mvc, session);
        clock.advance(Duration.ofSeconds(1));
        passwordReset.forgot(ANA);
        passwordReset.reset(tokenIn(emails.sentTo(ANA).getLast()), "a-brand-new-password");

        var fresh = auth.login(ANA, "a-brand-new-password", "203.0.113.10");
        mvc.perform(as(fresh, get("/api/v1/me/export")).header(ReauthService.HEADER, token))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("REAUTH_REQUIRED"));
        var after = reauth(fresh, "{\"password\":\"a-brand-new-password\"}")
                .andReturn()
                .getResponse()
                .getContentAsString();
        mvc.perform(as(fresh, get("/api/v1/me/export"))
                        .header(ReauthService.HEADER, JsonPath.<String>read(after, "$.reauthToken")))
                .andExpect(status().isOk());
    }

    @Test
    void theTokenExpiresAfterFiveMinutes() throws Exception {
        var session = account(ANA);
        var token = reauthWithPassword(mvc, session);

        clock.advance(Duration.ofMinutes(5).plusSeconds(1));

        // A new access token (the old one also expires): only the reauth token is too old.
        var fresh = auth.login(ANA, PASSWORD, "203.0.113.10");
        mvc.perform(as(fresh, get("/api/v1/me/export")).header(ReauthService.HEADER, token))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("REAUTH_REQUIRED"));
    }

    @Test
    void anAccessTokenIsNotAReauthTokenNorTheOtherWayRound() throws Exception {
        var session = account(ANA);
        var token = reauthWithPassword(mvc, session);

        mvc.perform(as(session, get("/api/v1/me/export")).header(ReauthService.HEADER, session.accessToken()))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("REAUTH_REQUIRED"));
        mvc.perform(get("/api/v1/me").header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void aReauthTokenOnlyWorksForItsOwnAccount() throws Exception {
        var ana = account(ANA);
        var bea = account(BEA);
        var beaToken = reauthWithPassword(mvc, bea);

        mvc.perform(as(ana, get("/api/v1/me/export")).header(ReauthService.HEADER, beaToken))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("REAUTH_REQUIRED"));
    }

    @Test
    void exactlyOneProofIsAccepted() throws Exception {
        var session = account(ANA);

        reauth(session, "{}").andExpect(status().isBadRequest());
        reauth(session, "{\"password\":\"%s\",\"googleIdToken\":\"x\"}".formatted(PASSWORD))
                .andExpect(status().isBadRequest());
    }

    private static MockHttpServletRequestBuilder[] sensitiveActions() {
        return new MockHttpServletRequestBuilder[] {
            delete("/api/v1/me"),
            get("/api/v1/me/export"),
            post("/api/v1/me/email")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{\"newEmail\":\"n@example.test\"}"),
            delete("/api/v1/me/password"),
            delete("/api/v1/me/identities/google")
        };
    }

    private ResultActions reauth(Session session, String body) throws Exception {
        return mvc.perform(as(
                session,
                post("/api/v1/me/reauth")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body)));
    }

    private Session account(String email) {
        auth.register(registration(email));
        jdbc.sql("update account set email_verified = true where email = ?")
                .param(email)
                .update();
        return auth.login(email, PASSWORD, "203.0.113.10");
    }
}
