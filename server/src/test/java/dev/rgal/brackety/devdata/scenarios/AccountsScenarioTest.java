package dev.rgal.brackety.devdata.scenarios;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.devdata.ScenarioContext;
import dev.rgal.brackety.local.EmbeddedPostgresConfig;
import java.time.Clock;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.support.TransactionOperations;
import org.springframework.web.ErrorResponseException;

// The daily purge would delete the 7-day account if it fired mid-test.
@SpringBootTest(properties = "brackety.auth.unverified-purge-initial-delay=P3650D")
@Import(EmbeddedPostgresConfig.class)
class AccountsScenarioTest {

    @Autowired
    AuthService auth;

    @Autowired
    Clock clock;

    @Autowired
    TransactionOperations transactions;

    @Test
    void seedsLoginReadyAccountsAndOneLockedAccount() {
        var scenario = new AccountsScenario(auth);

        transactions.executeWithoutResult(status -> scenario.seed(new ScenarioContext(clock)));

        assertThat(auth.login("club@example.test", AccountsScenario.PASSWORD, "127.0.0.1")
                        .accessToken())
                .isNotBlank();
        assertThatThrownBy(() -> auth.login(AccountsScenario.LOCKED_EMAIL, AccountsScenario.PASSWORD, "127.0.0.1"))
                .isInstanceOfSatisfying(
                        ErrorResponseException.class,
                        e -> assertThat(e.getStatusCode()).isEqualTo(HttpStatus.TOO_MANY_REQUESTS));
    }
}
