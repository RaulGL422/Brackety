package dev.rgal.brackety.devdata.scenarios;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.devdata.ScenarioContext;
import dev.rgal.brackety.local.EmbeddedPostgresConfig;
import java.sql.Timestamp;
import java.time.Clock;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.transaction.support.TransactionOperations;
import org.springframework.web.ErrorResponseException;

@SpringBootTest(properties = "brackety.auth.unverified-purge-initial-delay=P3650D")
@Import(EmbeddedPostgresConfig.class)
class SuperadminScenarioTest {

    @Autowired
    AuthService auth;

    @Autowired
    JdbcClient jdbc;

    @Autowired
    Clock clock;

    @Autowired
    TransactionOperations transactions;

    @Test
    void seedsOrganizersToValidateAndAnEmailAndAnIpLock() {
        var scenario = new SuperadminScenario(auth, jdbc);

        transactions.executeWithoutResult(status -> scenario.seed(new ScenarioContext(clock)));

        assertThat(jdbc.sql("select a.email from profile p join account a on a.id = p.account_id"
                                + " where p.type in ('CLUB', 'EXTERNAL_ENTITY') and not p.validated order by a.email")
                        .query(String.class)
                        .list())
                .containsExactly("club@example.test", "entidad@example.test");
        assertThat(jdbc.sql("select count(*) from login_attempt where locked_until > ?")
                        .param(Timestamp.from(clock.instant()))
                        .query(Integer.class)
                        .single())
                .isEqualTo(2);
        assertLocked(SuperadminScenario.LOCKED_EMAIL, "127.0.0.1");
        assertLocked("club@example.test", SuperadminScenario.LOCKED_IP);
    }

    private void assertLocked(String email, String ip) {
        assertThatThrownBy(() -> auth.login(email, SuperadminScenario.PASSWORD, ip))
                .isInstanceOfSatisfying(
                        ErrorResponseException.class,
                        e -> assertThat(e.getStatusCode()).isEqualTo(HttpStatus.TOO_MANY_REQUESTS));
    }
}
