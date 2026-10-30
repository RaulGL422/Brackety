package dev.rgal.brackety.auth;

import static dev.rgal.brackety.auth.EmailVerificationTest.assertInvalidLink;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Duration;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

class PasswordResetTest extends AuthIntegrationTest {

    private static final String ANA = "ana@example.test";
    private static final String IP = "203.0.113.10";
    private static final String NEW_PASSWORD = "a-brand-new-password";

    @Autowired
    AuthService auth;

    @Autowired
    SessionService sessions;

    @Autowired
    PasswordResetService passwordReset;

    @BeforeEach
    void registerAna() {
        auth.register(registration(ANA));
        emails.reset();
    }

    @Test
    void forgotSendsAOneHourResetLink() {
        passwordReset.forgot("ANA@example.test");

        var email = emails.sentTo(ANA).getFirst();
        assertThat(email.link()).startsWith("http://localhost:5000/reset-password?token=");
        clock.advance(Duration.ofHours(1));
        assertInvalidLink(() -> passwordReset.reset(tokenIn(email), NEW_PASSWORD));
    }

    @Test
    void forgotForAnUnknownEmailSendsNothingAndDoesNotFail() {
        passwordReset.forgot("nobody@example.test");

        assertThat(emails.sent()).isEmpty();
        assertThat(count("email_token where purpose = 'RESET_PASSWORD'")).isZero();
    }

    @Test
    void forgotSendsAtMostOneEmailPerMinuteAndInvalidatesTheEarlierLink() {
        passwordReset.forgot(ANA);
        var first = tokenIn(emails.sentTo(ANA).getFirst());
        clock.advance(Duration.ofSeconds(30));
        passwordReset.forgot(ANA);
        assertThat(emails.sentTo(ANA)).hasSize(1);

        clock.advance(Duration.ofSeconds(31));
        passwordReset.forgot(ANA);

        assertThat(emails.sentTo(ANA)).hasSize(2);
        assertInvalidLink(() -> passwordReset.reset(first, NEW_PASSWORD));
    }

    @Test
    void resetChangesThePasswordVerifiesTheEmailClosesSessionsAndWarns() {
        var session = auth.login(ANA, PASSWORD, IP);
        passwordReset.forgot(ANA);
        var token = tokenIn(emails.sentTo(ANA).getFirst());

        passwordReset.reset(token, NEW_PASSWORD);

        assertThatThrownBy(() -> auth.login(ANA, PASSWORD, IP)).isInstanceOf(AuthException.class);
        assertThat(auth.login(ANA, NEW_PASSWORD, IP).emailVerified()).isTrue();
        assertThatThrownBy(() -> sessions.refresh(session.refreshToken())).isInstanceOf(AuthException.class);
        assertThat(emails.sentTo(ANA).getLast().subject()).isEqualTo("Tu contraseña de Brackety ha cambiado");
    }

    @Test
    void resetLiftsTheEmailLockButKeepsTheIpCounter() {
        for (int i = 0; i < 5; i++) {
            assertThatThrownBy(() -> auth.login(ANA, "wrong-password", IP)).isInstanceOf(AuthException.class);
        }
        assertThatThrownBy(() -> auth.login(ANA, PASSWORD, "198.51.100.1")).isInstanceOf(AuthException.class);
        passwordReset.forgot(ANA);

        // The lock notice came first; the reset link is the last email.
        passwordReset.reset(tokenIn(emails.sentTo(ANA).getLast()), NEW_PASSWORD);

        assertThat(count("login_attempt where attempt_key like 'email:%'")).isZero();
        assertThat(jdbc.sql("select failures from login_attempt where ip = ?")
                        .param(IP)
                        .query(Integer.class)
                        .single())
                .isEqualTo(5);
        assertThat(auth.login(ANA, NEW_PASSWORD, "198.51.100.1").accessToken()).isNotBlank();
    }

    @Test
    void theResetLinkWorksOnlyOnce() {
        passwordReset.forgot(ANA);
        var token = tokenIn(emails.sentTo(ANA).getFirst());
        passwordReset.reset(token, NEW_PASSWORD);

        assertInvalidLink(() -> passwordReset.reset(token, "yet-another-password"));
    }

    @Test
    void aVerificationTokenCannotResetThePassword() {
        auth.register(registration("bob@example.test"));

        var verifyToken = tokenIn(emails.sentTo("bob@example.test").getFirst());
        assertInvalidLink(() -> passwordReset.reset(verifyToken, NEW_PASSWORD));
    }
}
