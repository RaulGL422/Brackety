package dev.rgal.brackety.common;

import dev.rgal.brackety.local.EmbeddedPostgresConfig;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.simple.JdbcClient;

/**
 * Through the real Tomcat (MockMvc skips its valves): which IP the rate limiter and the sign-in lockout see when a
 * request from 127.0.0.1 (a private address, trusted as a proxy by default) carries X-Forwarded-For.
 */
@SpringBootTest(
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = "brackety.rate-limit.auth-per-minute=2")
@Import(EmbeddedPostgresConfig.class)
abstract class ForwardedForTest {

    @LocalServerPort
    int port;

    @Autowired
    JdbcClient jdbc;

    private final HttpClient http = HttpClient.newHttpClient();

    @BeforeEach
    void noAttempts() {
        jdbc.sql("truncate login_attempt").update();
    }

    /** Five failed sign-ins, each claiming another client IP; their statuses. */
    List<Integer> signInsFromSpoofedIps() throws Exception {
        var statuses = new ArrayList<Integer>();
        for (int i = 0; i < 5; i++) {
            var request = HttpRequest.newBuilder(URI.create("http://127.0.0.1:" + port + "/api/v1/auth/login"))
                    .header("Content-Type", "application/json")
                    .header("X-Forwarded-For", "203.0.113." + (i + 1))
                    .POST(HttpRequest.BodyPublishers.ofString(
                            "{\"email\":\"nobody@example.test\",\"password\":\"wrong-password\"}"))
                    .build();
            statuses.add(
                    http.send(request, HttpResponse.BodyHandlers.discarding()).statusCode());
        }
        return statuses;
    }

    List<String> lockoutIps() {
        return jdbc.sql("select ip from login_attempt where ip is not null order by ip")
                .query(String.class)
                .list();
    }
}
