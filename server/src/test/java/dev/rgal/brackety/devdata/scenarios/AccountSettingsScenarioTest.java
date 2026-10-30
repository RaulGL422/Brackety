package dev.rgal.brackety.devdata.scenarios;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.ProfileRepository;
import dev.rgal.brackety.devdata.ScenarioContext;
import java.time.Duration;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.support.TransactionOperations;

class AccountSettingsScenarioTest extends AuthIntegrationTest {

    @Autowired
    AuthService auth;

    @Autowired
    AccountRepository accounts;

    @Autowired
    ProfileRepository profiles;

    @Autowired
    TransactionOperations transactions;

    @Test
    void seedsAStudentHelperAndAccountsDeletedOneAndThirtyDaysAgoByTheClock() {
        var scenario = new AccountSettingsScenario(auth, accounts, profiles);

        transactions.executeWithoutResult(status -> scenario.seed(new ScenarioContext(clock)));

        assertThat(jdbc.sql("select p.type from profile p join account a on a.id = p.account_id"
                                + " where a.email = ? and a.email_verified order by p.type")
                        .param(AccountSettingsScenario.STUDENT_HELPER)
                        .query(String.class)
                        .list())
                .containsExactly("HELPER", "STUDENT");
        assertThat(daysSinceDeletion(AccountSettingsScenario.DELETED_DAY_1)).isEqualTo(1);
        assertThat(daysSinceDeletion(AccountSettingsScenario.DELETED_DAY_30)).isEqualTo(30);
        assertThatThrownBy(() -> auth.login(
                        AccountSettingsScenario.DELETED_DAY_1, AccountSettingsScenario.PASSWORD, "127.0.0.1"))
                .isInstanceOfSatisfying(
                        AuthException.class,
                        e -> assertThat(e.getBody().getProperties()).containsEntry("code", "ACCOUNT_PENDING_DELETION"));
        // The purge query takes the day-30 account only.
        transactions.executeWithoutResult(
                status -> accounts.deleteDeletedBefore(clock.instant().minus(Duration.ofDays(30))));
        assertThat(count("account where status = 'DELETED'")).isOne();
    }

    private long daysSinceDeletion(String email) {
        var deletedAt = jdbc.sql("select deleted_at from account where email = ? and status = 'DELETED'")
                .param(email)
                .query(Instant.class)
                .single();
        return Duration.between(deletedAt, clock.instant()).toDays();
    }
}
