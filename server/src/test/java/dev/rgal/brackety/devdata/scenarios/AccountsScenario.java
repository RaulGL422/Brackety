package dev.rgal.brackety.devdata.scenarios;

import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.account.ProfileType;
import dev.rgal.brackety.devdata.DevScenario;
import dev.rgal.brackety.devdata.Scenario;
import dev.rgal.brackety.devdata.ScenarioContext;
import java.util.Map;
import org.springframework.web.ErrorResponseException;

@DevScenario
class AccountsScenario implements Scenario {

    static final String PASSWORD = "brackety-demo";
    static final String LOCKED_EMAIL = "bloqueada@example.test";

    private static final Map<String, ProfileType> ACCOUNTS = Map.of(
            "club@example.test",
            ProfileType.CLUB,
            "entidad@example.test",
            ProfileType.EXTERNAL_ENTITY,
            "ayudante@example.test",
            ProfileType.HELPER,
            "externo@example.test",
            ProfileType.EXTERNAL,
            "alumno@example.test",
            ProfileType.STUDENT,
            LOCKED_EMAIL,
            ProfileType.STUDENT);

    private final AuthService auth;

    AccountsScenario(AuthService auth) {
        this.auth = auth;
    }

    @Override
    public String name() {
        return "accounts";
    }

    @Override
    public String description() {
        return "One account per profile (password '" + PASSWORD + "') and " + LOCKED_EMAIL
                + " locked for 15 min after 5 failed logins";
    }

    @Override
    public void seed(ScenarioContext ctx) {
        ACCOUNTS.forEach((email, profile) -> auth.register(SignUps.of(email, PASSWORD, profile, "es", ctx)));
        for (int i = 0; i < 5; i++) {
            try {
                auth.login(LOCKED_EMAIL, "wrong-password", "scenario-" + i);
            } catch (ErrorResponseException expected) {
                // Each failure counts towards the lock; this is the point of the loop.
            }
        }
    }
}
