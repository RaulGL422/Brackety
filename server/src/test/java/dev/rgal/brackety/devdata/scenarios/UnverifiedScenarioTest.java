package dev.rgal.brackety.devdata.scenarios;

import static org.assertj.core.api.Assertions.assertThat;

import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.devdata.ScenarioContext;
import dev.rgal.brackety.local.EmbeddedPostgresConfig;
import jakarta.persistence.EntityManager;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.transaction.support.TransactionOperations;

// The daily purge would delete the 7-day account if it fired mid-test.
@SpringBootTest(properties = "brackety.auth.unverified-purge-initial-delay=P3650D")
@Import(EmbeddedPostgresConfig.class)
class UnverifiedScenarioTest {

    @Autowired
    AuthService auth;

    @Autowired
    JdbcClient jdbc;

    @Autowired
    Clock clock;

    @Autowired
    TransactionOperations transactions;

    @Autowired
    EntityManager entityManager;

    @Test
    void seedsUnverifiedAccountsAgedZeroFiveAndSevenDaysByTheClock() {
        var scenario = new UnverifiedScenario(auth, jdbc, entityManager);

        transactions.executeWithoutResult(status -> scenario.seed(new ScenarioContext(clock)));

        assertThat(ageInDays(UnverifiedScenario.NEW_EMAIL)).isZero();
        assertThat(ageInDays(UnverifiedScenario.REMINDER_EMAIL)).isEqualTo(5);
        assertThat(ageInDays(UnverifiedScenario.PURGE_EMAIL)).isEqualTo(7);
        assertThat(auth.login(UnverifiedScenario.NEW_EMAIL, UnverifiedScenario.PASSWORD, "127.0.0.1")
                        .emailVerified())
                .isFalse();
    }

    private long ageInDays(String email) {
        var createdAt = jdbc.sql("select created_at from account where email = ? and not email_verified")
                .param(email)
                .query(Instant.class)
                .single();
        return Duration.between(createdAt, clock.instant()).toDays();
    }
}
