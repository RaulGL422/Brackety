package dev.rgal.brackety.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import dev.rgal.brackety.auth.account.ProfileType;
import dev.rgal.brackety.auth.dto.RegisterRequest;
import dev.rgal.brackety.auth.session.SessionService;
import dev.rgal.brackety.notifications.Email;
import java.time.Duration;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

// Emails sent from the existing auth flows: duplicate registration, lock, refresh reuse, and their language.
class SecurityEmailsTest extends AuthIntegrationTest {

    private static final String ANA = "ana@example.test";
    private static final String IP = "203.0.113.10";

    @Autowired
    AuthService auth;

    @Autowired
    SessionService sessions;

    @Test
    void duplicateRegistrationTellsTheOwnerInTheirLanguage() {
        auth.register(registration(ANA));
        emails.reset();

        auth.register(new RegisterRequest(
                "ANA@example.test",
                "another-password",
                ProfileType.STUDENT,
                LocalDate.of(1980, 1, 1),
                null,
                null,
                TERMS_VERSION,
                PRIVACY_VERSION,
                "en"));

        var email = emails.sentTo(ANA).getFirst();
        assertThat(email.subject()).isEqualTo("Ya tienes una cuenta en Brackety");
        assertThat(email.link()).isEqualTo("http://localhost:5000/forgot-password");
    }

    @Test
    void repeatedDuplicateRegistrationsSendAtMostOneEmailPerMinute() {
        auth.register(registration(ANA));
        emails.reset();

        auth.register(registration(ANA));
        clock.advance(Duration.ofSeconds(59));
        auth.register(registration(ANA));
        assertThat(emails.sentTo(ANA)).hasSize(1);

        clock.advance(Duration.ofSeconds(1));
        auth.register(registration(ANA));
        assertThat(emails.sentTo(ANA)).hasSize(2);
    }

    @Test
    void emailsUseTheAccountLanguage() {
        auth.register(registration(ANA));
        auth.register(registration("bob@example.test", ProfileType.CLUB, "en"));

        var spanish = emails.sentTo(ANA).getFirst();
        var english = emails.sentTo("bob@example.test").getFirst();
        assertThat(spanish.subject()).isEqualTo("Confirma tu email en Brackety");
        assertThat(spanish.text()).contains("caduca en 24 horas", spanish.link());
        assertThat(english.subject()).isEqualTo("Confirm your email on Brackety");
        assertThat(english.text()).contains("expires in 24 hours", english.link());
        assertThat(english.html()).contains("<a href=\"" + english.link() + "\">Confirm email</a>");
    }

    @Test
    void aLockSendsOneEmailWithTheLockId() {
        auth.register(registration(ANA));
        emails.reset();

        failLogin(5);
        failLogin(3);

        var lockId = jdbc.sql("select lock_id from login_attempt where account_id is not null")
                .query(String.class)
                .single();
        assertThat(emails.sentTo(ANA)).singleElement().satisfies(email -> {
            assertThat(email.subject()).isEqualTo("Tu cuenta de Brackety se ha bloqueado 15 minutos");
            assertThat(email.text()).contains(lockId);
            assertThat(email.link()).endsWith("/forgot-password");
        });
    }

    @Test
    void eachNewLockSendsItsOwnEmail() {
        auth.register(registration(ANA));
        emails.reset();
        failLogin(5);
        clock.advance(Duration.ofMinutes(15));

        failLogin(5);

        assertThat(emails.sentTo(ANA)).hasSize(2);
    }

    @Test
    void anUnknownEmailThatLocksSendsNothing() {
        for (int i = 0; i < 5; i++) {
            var ip = "198.51.100." + i;
            assertThatThrownBy(() -> auth.login("nobody@example.test", "wrong-password", ip));
        }

        assertThat(emails.sent()).isEmpty();
    }

    @Test
    void refreshReuseAfterTheGraceWarnsTheOwner() {
        auth.register(registration(ANA));
        var first = auth.login(ANA, PASSWORD, IP);
        sessions.refresh(first.refreshToken());
        emails.reset();

        clock.advance(Duration.ofSeconds(10));
        sessions.refresh(first.refreshToken());
        assertThat(emails.sent()).isEmpty();

        clock.advance(Duration.ofSeconds(1));
        assertThatThrownBy(() -> sessions.refresh(first.refreshToken()));
        assertThat(emails.sentTo(ANA))
                .extracting(Email::subject)
                .containsExactly("Posible acceso no autorizado a tu cuenta de Brackety");
    }

    @Test
    void aFailingEmailProviderDoesNotBreakRegistration() {
        emails.failFromNowOn();

        auth.register(registration(ANA));

        assertThat(count("account")).isOne();
        assertThat(count("email_token")).isOne();
    }

    // Each failure from a different IP, so only the email counter adds up.
    private void failLogin(int times) {
        for (int i = 0; i < times; i++) {
            var ip = "198.51.100." + i;
            assertThatThrownBy(() -> auth.login(ANA, "wrong-password", ip)).isInstanceOf(AuthException.class);
        }
    }
}
