package dev.rgal.brackety.auth;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.auth.account.ProfileType;
import dev.rgal.brackety.auth.dto.RegisterRequest;
import dev.rgal.brackety.auth.dto.RegistrationDetails;
import dev.rgal.brackety.auth.google.FakeGoogle;
import dev.rgal.brackety.auth.session.SessionService.Session;
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
import java.util.concurrent.atomic.AtomicBoolean;
import org.junit.jupiter.api.BeforeEach;
import org.mockito.Mockito;
import org.mockito.stubbing.Answer;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;
import org.springframework.test.web.servlet.result.MockMvcResultMatchers;

// The purge jobs never start on their own here: tests run it with the clock where they want it.
@SpringBootTest(
        properties = {
            "brackety.rate-limit.per-minute=100000",
            "brackety.rate-limit.auth-per-minute=100000",
            "brackety.auth.unverified-purge-initial-delay=P3650D",
            "brackety.auth.deleted-purge-initial-delay=P3650D",
            // A list, as in production (web and Android client ids).
            "brackety.auth.google-client-ids=other-client.apps.googleusercontent.com, " + FakeGoogle.CLIENT_ID,
            "brackety.superadmin.email=" + AuthIntegrationTest.SUPERADMIN_EMAIL,
            "brackety.superadmin.password-hash=" + AuthIntegrationTest.SUPERADMIN_PASSWORD_HASH
        })
@AutoConfigureMockMvc
@Import(AuthTestConfig.class)
public abstract class AuthIntegrationTest {

    protected static final String PASSWORD = "correct-horse-battery";
    protected static final String SUPERADMIN_EMAIL = "superadmin@example.test";
    // PASSWORD, hashed with SuperadminPasswordHash.
    protected static final String SUPERADMIN_PASSWORD_HASH =
            "$argon2id$v=19$m=19456,t=2,p=1$AcplTC/dLHhH1XfsBNB0pA$kByTPtLzWseDp3T+lGkrQ/yCNZ+rteO5cQBksgwWHMs";

    @Autowired
    protected MutableClock clock;

    @Autowired
    protected JdbcClient jdbc;

    @Autowired
    protected CapturingEmailSender emails;

    @BeforeEach
    protected void resetDatabaseClockAndEmails() {
        jdbc.sql("truncate account, login_attempt, admin_audit cascade").update();
        clock.set(AuthTestConfig.START);
        emails.reset();
    }

    protected static RegisterRequest registration(String email) {
        return registration(email, LocalDate.of(1990, 5, 20));
    }

    protected static RegisterRequest registration(String email, LocalDate birthDate) {
        return new RegisterRequest(email, PASSWORD, birthDate, ProfileType.CLUB, "2027-01", "2027-02", "es");
    }

    protected static RegistrationDetails details(LocalDate birthDate) {
        return new RegistrationDetails(birthDate, ProfileType.STUDENT, "2027-01", "2027-02", "en");
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

    /** For a {@code @MockitoSpyBean} repository: the first call returns {@code value}, the rest go to the real one. */
    protected static Answer<Object> firstCallReturns(Object value, Object spy) {
        var real = Mockito.mockingDetails(spy).getMockCreationSettings().getDefaultAnswer();
        var first = new AtomicBoolean(true);
        return invocation -> first.getAndSet(false) ? value : real.answer(invocation);
    }

    protected static MockHttpServletRequestBuilder as(Session session, MockHttpServletRequestBuilder request) {
        return request.header(HttpHeaders.AUTHORIZATION, "Bearer " + session.accessToken());
    }

    /** Proves the password again through the API and returns the token for the X-Reauth header. */
    protected static String reauthWithPassword(MockMvc mvc, Session session) throws Exception {
        return reauth(mvc, session, "{\"password\":\"%s\"}".formatted(PASSWORD));
    }

    protected static String reauthWithGoogle(MockMvc mvc, Session session, String idToken) throws Exception {
        return reauth(mvc, session, "{\"googleIdToken\":\"%s\"}".formatted(idToken));
    }

    private static String reauth(MockMvc mvc, Session session, String body) throws Exception {
        var response = mvc.perform(as(
                        session,
                        MockMvcRequestBuilders.post("/api/v1/me/reauth")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body)))
                .andExpect(MockMvcResultMatchers.status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        return JsonPath.read(response, "$.reauthToken");
    }

    protected int count(String table) {
        return jdbc.sql("select count(*) from " + table).query(Integer.class).single();
    }
}
