package dev.rgal.brackety.auth;

import dev.rgal.brackety.auth.account.ProfileType;
import dev.rgal.brackety.auth.dto.RegisterRequest;
import dev.rgal.brackety.common.MutableClock;
import dev.rgal.brackety.notifications.CapturingEmailSender;
import dev.rgal.brackety.notifications.Email;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.simple.JdbcClient;

// The purge job never starts on its own here: tests run it with the clock where they want it.
@SpringBootTest(
        properties = {
            "brackety.rate-limit.per-minute=100000",
            "brackety.rate-limit.auth-per-minute=100000",
            "brackety.auth.unverified-purge-initial-delay=P3650D"
        })
@AutoConfigureMockMvc
@Import(AuthTestConfig.class)
public abstract class AuthIntegrationTest {

    protected static final String PASSWORD = "correct-horse-battery";

    @Autowired
    protected MutableClock clock;

    @Autowired
    protected JdbcClient jdbc;

    @Autowired
    protected CapturingEmailSender emails;

    @BeforeEach
    protected void resetDatabaseClockAndEmails() {
        jdbc.sql("truncate account, login_attempt cascade").update();
        clock.set(AuthTestConfig.START);
        emails.reset();
    }

    protected static RegisterRequest registration(String email) {
        return registration(email, LocalDate.of(1990, 5, 20));
    }

    protected static RegisterRequest registration(String email, LocalDate birthDate) {
        return new RegisterRequest(email, PASSWORD, birthDate, ProfileType.CLUB, "2027-01", "2027-02", "es");
    }

    // The raw token is only in the emailed link, as a real user would get it.
    protected static String tokenIn(Email email) {
        return email.link().substring(email.link().indexOf("token=") + "token=".length());
    }

    /** Runs the call on two threads released together; returns "ok" or the HTTP status of each. */
    protected static List<String> runTwiceAtOnce(Runnable call) throws Exception {
        var start = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var results = new ArrayList<Future<String>>();
            for (int i = 0; i < 2; i++) {
                results.add(pool.submit(() -> {
                    if (!start.await(30, TimeUnit.SECONDS)) {
                        throw new IllegalStateException("Start signal never came");
                    }
                    try {
                        call.run();
                        return "ok";
                    } catch (AuthException e) {
                        return String.valueOf(e.getStatusCode().value());
                    }
                }));
            }
            start.countDown();
            var outcomes = new ArrayList<String>();
            for (var result : results) {
                outcomes.add(result.get(30, TimeUnit.SECONDS));
            }
            return outcomes;
        }
    }

    protected int count(String table) {
        return jdbc.sql("select count(*) from " + table).query(Integer.class).single();
    }
}
