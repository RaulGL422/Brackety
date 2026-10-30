package dev.rgal.brackety.auth.session;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.email.PasswordResetService;
import dev.rgal.brackety.auth.session.SessionService.Session;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;

class SessionRevocationTest extends AuthIntegrationTest {

    private static final String ANA = "ana@example.test";
    private static final String IP = "203.0.113.10";
    private static final String NEW_PASSWORD = "a-brand-new-password";

    @Autowired
    MockMvc mvc;

    @Autowired
    AuthService auth;

    @Autowired
    PasswordResetService passwordReset;

    @Test
    void anAccessTokenIssuedBeforeAResetIsRefusedEverywhere() throws Exception {
        var before = account();
        clock.advance(Duration.ofSeconds(1));

        resetPassword();

        mvc.perform(as(before, get("/api/v1/me"))).andExpect(status().isUnauthorized());
        mvc.perform(as(before, get("/api/v1/events"))).andExpect(status().isUnauthorized());
    }

    // The clock is fixed: the new session starts in the same second as the reset and must work.
    @Test
    void anAccessTokenIssuedAfterTheResetWorks() throws Exception {
        account();
        clock.advance(Duration.ofSeconds(1));
        resetPassword();

        var after = auth.login(ANA, NEW_PASSWORD, IP);

        mvc.perform(as(after, get("/api/v1/me"))).andExpect(status().isOk());
        mvc.perform(as(after, get("/api/v1/events"))).andExpect(status().isOk());
    }

    @Test
    void anAccessTokenOfAnAccountThatNoLongerExistsIsRefused() throws Exception {
        var session = account();

        jdbc.sql("delete from account").update();

        mvc.perform(as(session, get("/api/v1/me"))).andExpect(status().isUnauthorized());
    }

    private void resetPassword() {
        passwordReset.forgot(ANA);
        passwordReset.reset(tokenIn(emails.sentTo(ANA).getLast()), NEW_PASSWORD);
    }

    private Session account() {
        auth.register(registration(ANA));
        jdbc.sql("update account set email_verified = true where email = ?")
                .param(ANA)
                .update();
        return auth.login(ANA, PASSWORD, IP);
    }
}
