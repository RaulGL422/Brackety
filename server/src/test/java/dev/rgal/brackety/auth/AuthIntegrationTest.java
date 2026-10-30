package dev.rgal.brackety.auth;

import dev.rgal.brackety.auth.dto.RegisterRequest;
import dev.rgal.brackety.common.MutableClock;
import java.time.LocalDate;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.simple.JdbcClient;

@SpringBootTest(properties = {"brackety.rate-limit.per-minute=100000", "brackety.rate-limit.auth-per-minute=100000"})
@AutoConfigureMockMvc
@Import(AuthTestConfig.class)
abstract class AuthIntegrationTest {

    static final String PASSWORD = "correct-horse-battery";

    @Autowired
    MutableClock clock;

    @Autowired
    JdbcClient jdbc;

    @BeforeEach
    void resetDatabaseAndClock() {
        jdbc.sql("truncate account, login_attempt cascade").update();
        clock.set(AuthTestConfig.START);
    }

    static RegisterRequest registration(String email) {
        return registration(email, LocalDate.of(1990, 5, 20));
    }

    static RegisterRequest registration(String email, LocalDate birthDate) {
        return new RegisterRequest(email, PASSWORD, birthDate, ProfileType.CLUB, "2027-01", "2027-02", "es");
    }

    int count(String table) {
        return jdbc.sql("select count(*) from " + table).query(Integer.class).single();
    }
}
