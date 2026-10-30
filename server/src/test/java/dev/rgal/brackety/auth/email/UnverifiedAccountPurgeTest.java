package dev.rgal.brackety.auth.email;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.session.SessionService;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

class UnverifiedAccountPurgeTest extends AuthIntegrationTest {

    @Autowired
    AuthService auth;

    @Autowired
    SessionService sessions;

    @Autowired
    EmailVerificationService verification;

    @Autowired
    UnverifiedAccountPurge purge;

    @Test
    void remindsOnDayFiveOnlyOnceWithAWorkingLink() {
        auth.register(registration("ana@example.test"));
        clock.advance(Duration.ofDays(5).minusSeconds(1));
        purge.run();
        assertThat(emails.sentTo("ana@example.test")).hasSize(1);

        clock.advance(Duration.ofSeconds(1));
        purge.run();
        clock.advance(Duration.ofHours(12));
        purge.run();

        var reminders = emails.sentTo("ana@example.test").stream()
                .filter(e -> e.subject().equals("Tu cuenta de Brackety se borrará en 2 días"))
                .toList();
        assertThat(reminders).hasSize(1);
        verification.verify(tokenIn(reminders.getFirst()));
        assertThat(count("account where email_verified")).isOne();
    }

    @Test
    void deletesOnDaySevenWithEverythingItOwns() {
        auth.register(registration("ana@example.test"));
        var session = auth.login("ana@example.test", PASSWORD, "203.0.113.10");
        for (int i = 0; i < 2; i++) {
            var ip = "198.51.100." + i;
            assertThatThrownBy(() -> auth.login("ana@example.test", "wrong-password", ip));
        }
        clock.advance(Duration.ofDays(7));

        purge.run();

        for (var table : new String[] {"account", "profile", "consent", "email_token", "refresh_token"}) {
            assertThat(count(table)).as(table).isZero();
        }
        assertThat(count("login_attempt where account_id is not null")).isZero();
        assertThatThrownBy(() -> sessions.refresh(session.refreshToken())).isInstanceOf(AuthException.class);
    }

    @Test
    void keepsVerifiedAccountsAndUnverifiedOnesYoungerThanSevenDays() {
        auth.register(registration("verified@example.test"));
        verification.verify(tokenIn(emails.sentTo("verified@example.test").getFirst()));
        clock.advance(Duration.ofDays(1));
        auth.register(registration("six-days@example.test"));
        clock.advance(Duration.ofDays(6));

        purge.run();

        assertThat(jdbc.sql("select email from account").query(String.class).list())
                .containsExactlyInAnyOrder("verified@example.test", "six-days@example.test");
    }
}
