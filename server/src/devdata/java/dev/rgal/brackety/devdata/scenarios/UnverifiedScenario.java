package dev.rgal.brackety.devdata.scenarios;

import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.account.ProfileType;
import dev.rgal.brackety.devdata.DevScenario;
import dev.rgal.brackety.devdata.Scenario;
import dev.rgal.brackety.devdata.ScenarioContext;
import jakarta.persistence.EntityManager;
import java.time.Duration;
import java.time.ZoneOffset;
import java.util.Map;
import org.springframework.jdbc.core.simple.JdbcClient;

@DevScenario
class UnverifiedScenario implements Scenario {

    static final String PASSWORD = "brackety-demo";
    static final String NEW_EMAIL = "nueva@example.test";
    static final String REMINDER_EMAIL = "recordatorio@example.test";
    static final String PURGE_EMAIL = "purga@example.test";

    // Days since sign-up: the daily job (also run 1 min after startup) reminds at 5 and deletes at 7.
    private static final Map<String, Integer> AGE_IN_DAYS = Map.of(NEW_EMAIL, 0, REMINDER_EMAIL, 5, PURGE_EMAIL, 7);

    private final AuthService auth;
    private final JdbcClient jdbc;
    private final EntityManager entityManager;

    UnverifiedScenario(AuthService auth, JdbcClient jdbc, EntityManager entityManager) {
        this.auth = auth;
        this.jdbc = jdbc;
        this.entityManager = entityManager;
    }

    @Override
    public String name() {
        return "unverified";
    }

    @Override
    public String description() {
        return "Unverified accounts (password '" + PASSWORD + "'): " + NEW_EMAIL + " just created, " + REMINDER_EMAIL
                + " due for the day-5 reminder, " + PURGE_EMAIL + " due for deletion";
    }

    @Override
    public void seed(ScenarioContext ctx) {
        AGE_IN_DAYS.forEach((email, days) -> {
            auth.register(SignUps.of(email, PASSWORD, ProfileType.STUDENT, "es", ctx));
            // The account is still a pending JPA insert; the plain SQL update below must see it.
            entityManager.flush();
            jdbc.sql("update account set created_at = ? where email = ?")
                    // Exact 24 h days, as the job counts them: minusDays would drift an hour across a DST change.
                    .param(ctx.now().toInstant().minus(Duration.ofDays(days)).atOffset(ZoneOffset.UTC))
                    .param(email)
                    .update();
        });
    }
}
