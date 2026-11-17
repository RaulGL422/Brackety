package dev.rgal.brackety.devdata.scenarios;

import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.account.ProfileType;
import dev.rgal.brackety.devdata.DevScenario;
import dev.rgal.brackety.devdata.Scenario;
import dev.rgal.brackety.devdata.ScenarioContext;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.web.ErrorResponseException;

@DevScenario
class SuperadminScenario implements Scenario {

    static final String PASSWORD = "brackety-demo";
    static final String LOCKED_EMAIL = "bloqueada@example.test";
    static final String LOCKED_IP = "198.51.100.66";

    private final AuthService auth;
    private final JdbcClient jdbc;

    SuperadminScenario(AuthService auth, JdbcClient jdbc) {
        this.auth = auth;
        this.jdbc = jdbc;
    }

    @Override
    public String name() {
        return "superadmin";
    }

    @Override
    public String description() {
        return "Organizers to validate (club@, entidad@) and one validated (club.validado@), " + LOCKED_EMAIL
                + " locked by email and IP " + LOCKED_IP + " locked, both for 15 min (password '" + PASSWORD + "')";
    }

    @Override
    public void seed(ScenarioContext ctx) {
        register(ctx, "club@example.test", ProfileType.CLUB, "es");
        register(ctx, "entidad@example.test", ProfileType.EXTERNAL_ENTITY, "en");
        register(ctx, "club.validado@example.test", ProfileType.CLUB, "es");
        register(ctx, LOCKED_EMAIL, ProfileType.STUDENT, "es");
        jdbc.sql("update profile set validated = true where account_id ="
                        + " (select id from account where email = 'club.validado@example.test')")
                .update();
        for (int i = 0; i < 5; i++) {
            failLogin(LOCKED_EMAIL, "scenario-" + i);
        }
        for (int i = 0; i < 30; i++) {
            failLogin("intruso" + i + "@example.test", LOCKED_IP);
        }
    }

    private void register(ScenarioContext ctx, String email, ProfileType profile, String locale) {
        auth.register(SignUps.of(email, PASSWORD, profile, locale, ctx));
    }

    private void failLogin(String email, String ip) {
        try {
            auth.login(email, "wrong-password", ip);
        } catch (ErrorResponseException expected) {
            // Each failure counts towards the lock; this is the point of the loops.
        }
    }
}
