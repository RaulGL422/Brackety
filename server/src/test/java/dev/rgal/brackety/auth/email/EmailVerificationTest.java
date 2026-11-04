package dev.rgal.brackety.auth.email;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.common.crypto.Sha256;
import java.time.Duration;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;

class EmailVerificationTest extends AuthIntegrationTest {

    private static final String ANA = "ana@example.test";

    @Autowired
    AuthService auth;

    @Autowired
    EmailVerificationService verification;

    @Autowired
    PasswordResetService passwordReset;

    @BeforeEach
    void registerAna() {
        auth.register(registration(ANA));
    }

    @Test
    void registrationSendsALinkThatVerifiesTheEmail() {
        var email = emails.sentTo(ANA).getFirst();
        assertThat(email.link()).startsWith("http://localhost:5000/verify-email?token=");

        verification.verify(tokenIn(email));

        assertThat(verified()).isTrue();
    }

    @Test
    void theTokenIsStoredOnlyAsAHash() {
        var token = tokenIn(emails.sentTo(ANA).getFirst());

        assertThat(jdbc.sql("select token_hash from email_token")
                        .query(String.class)
                        .single())
                .isEqualTo(Sha256.hex(token));
    }

    @Test
    void theLinkExpiresAfter24Hours() {
        var token = tokenIn(emails.sentTo(ANA).getFirst());
        clock.advance(Duration.ofHours(24));

        assertInvalidLink(() -> verification.verify(token));
        assertThat(verified()).isFalse();
    }

    @Test
    void theLinkWorksOnlyOnce() {
        var token = tokenIn(emails.sentTo(ANA).getFirst());
        verification.verify(token);

        assertInvalidLink(() -> verification.verify(token));
    }

    @Test
    void twoSimultaneousUsesOfTheLinkSucceedOnlyOnce() throws Exception {
        var token = tokenIn(emails.sentTo(ANA).getFirst());

        assertThat(runTwiceAtOnce(() -> verification.verify(token))).containsExactlyInAnyOrder("ok", "400");
        assertThat(count("email_token")).isZero();
    }

    @Test
    void anUnknownTokenIsRejected() {
        assertInvalidLink(() -> verification.verify("not-a-token"));
        assertThat(verified()).isFalse();
    }

    @Test
    void aResetTokenDoesNotVerify() {
        emails.reset();
        passwordReset.forgot(ANA);
        var resetToken = tokenIn(emails.sentTo(ANA).getFirst());

        assertInvalidLink(() -> verification.verify(resetToken));
    }

    @Test
    void resendInvalidatesTheEarlierLink() {
        var first = tokenIn(emails.sentTo(ANA).getFirst());
        clock.advance(Duration.ofSeconds(61));

        verification.resend("Ana@Example.test");

        var second = tokenIn(emails.sentTo(ANA).getLast());
        assertInvalidLink(() -> verification.verify(first));
        verification.verify(second);
        assertThat(verified()).isTrue();
    }

    @Test
    void resendSendsAtMostOneEmailPerMinute() {
        clock.advance(Duration.ofSeconds(59));
        verification.resend(ANA);
        assertThat(emails.sentTo(ANA)).hasSize(1);

        clock.advance(Duration.ofSeconds(2));
        verification.resend(ANA);
        verification.resend(ANA);
        assertThat(emails.sentTo(ANA)).hasSize(2);
    }

    @Test
    void resendSendsNothingForUnknownOrVerifiedAccounts() {
        verification.verify(tokenIn(emails.sentTo(ANA).getFirst()));
        emails.reset();
        clock.advance(Duration.ofMinutes(5));

        verification.resend(ANA);
        verification.resend("nobody@example.test");

        assertThat(emails.sent()).isEmpty();
    }

    private boolean verified() {
        return jdbc.sql("select email_verified from account")
                .query(Boolean.class)
                .single();
    }

    static void assertInvalidLink(Runnable call) {
        assertThatThrownBy(call::run)
                .isInstanceOfSatisfying(
                        AuthException.class, e -> assertThat(e.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
    }
}
