package dev.rgal.brackety.devdata.scenarios;

import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.Profile;
import dev.rgal.brackety.auth.account.ProfileRepository;
import dev.rgal.brackety.auth.account.ProfileType;
import dev.rgal.brackety.auth.dto.RegisterRequest;
import dev.rgal.brackety.devdata.DevScenario;
import dev.rgal.brackety.devdata.Scenario;
import dev.rgal.brackety.devdata.ScenarioContext;
import java.time.Duration;

@DevScenario
class AccountSettingsScenario implements Scenario {

    static final String PASSWORD = "brackety-demo";
    static final String STUDENT_HELPER = "alumno.ayudante@example.test";
    static final String DELETED_DAY_1 = "borrada.dia1@example.test";
    static final String DELETED_DAY_30 = "borrada.dia30@example.test";

    private final AuthService auth;
    private final AccountRepository accounts;
    private final ProfileRepository profiles;

    AccountSettingsScenario(AuthService auth, AccountRepository accounts, ProfileRepository profiles) {
        this.auth = auth;
        this.accounts = accounts;
        this.profiles = profiles;
    }

    @Override
    public String name() {
        return "account-settings";
    }

    @Override
    public String description() {
        return "Verified accounts (password '" + PASSWORD + "'): " + STUDENT_HELPER + " Student and Helper, "
                + DELETED_DAY_1 + " deleted yesterday (restorable), " + DELETED_DAY_30
                + " deleted 30 days ago (purged by the daily job 1 min after startup)";
    }

    @Override
    public void seed(ScenarioContext ctx) {
        var now = ctx.now().toInstant();
        var studentHelper = verified(STUDENT_HELPER, ctx);
        profiles.save(new Profile(studentHelper.getId(), ProfileType.HELPER, now));
        // Exact 24 h days, as the purge counts them.
        verified(DELETED_DAY_1, ctx).markDeleted(now.minus(Duration.ofDays(1)));
        verified(DELETED_DAY_30, ctx).markDeleted(now.minus(Duration.ofDays(30)));
    }

    private Account verified(String email, ScenarioContext ctx) {
        auth.register(new RegisterRequest(
                email, PASSWORD, ctx.daysFromToday(-30 * 365), ProfileType.STUDENT, "2027-01", "2027-01", "es"));
        var account = accounts.findByEmail(email).orElseThrow();
        account.markEmailVerified(ctx.now().toInstant());
        return account;
    }
}
