package dev.rgal.brackety;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.local.EmbeddedPostgresConfig;
import java.util.ArrayList;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest(
        properties = {
            "brackety.cors.allowed-origin-patterns=http://localhost:[*]",
            "brackety.rate-limit.auth-per-minute=2"
        })
@AutoConfigureMockMvc
@Import(EmbeddedPostgresConfig.class)
class BracketyApplicationTests {

    @Autowired
    MockMvc mvc;

    @Autowired
    JdbcClient jdbc;

    @Test
    void healthIsUp() throws Exception {
        mvc.perform(get("/actuator/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"));
    }

    @Test
    void runsOnPostgres18() {
        var version = jdbc.sql("show server_version").query(String.class).single();

        assertThat(version).startsWith("18.");
    }

    // No GOOGLE_CLIENT_ID here: the API starts and only Google sign-in is unavailable.
    @Test
    void googleSignInWithoutClientIdIs503() throws Exception {
        mvc.perform(post("/api/v1/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"idToken\":\"any\"}"))
                .andExpect(status().isServiceUnavailable())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.detail").value("Google sign-in is not configured."));
    }

    @Test
    void allowsConfiguredOrigin() throws Exception {
        mvc.perform(options("/api/v1/info")
                        .header("Origin", "http://localhost:5000")
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:5000"));
    }

    @Test
    void rejectsOtherOrigins() throws Exception {
        mvc.perform(options("/api/v1/info")
                        .header("Origin", "https://evil.example")
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(status().isForbidden());
    }

    @Test
    void rateLimiterAnswers429WithRetryAfter() throws Exception {
        var statuses = new ArrayList<Integer>();
        // Five calls against a limit of 2: even across a minute boundary one minute goes over.
        for (int i = 0; i < 5; i++) {
            var response = mvc.perform(post("/api/v1/auth/login").with(request -> {
                        request.setRemoteAddr("192.0.2.50");
                        return request;
                    }))
                    .andReturn()
                    .getResponse();
            statuses.add(response.getStatus());
            if (response.getStatus() == 429) {
                assertThat(response.getHeader("Retry-After")).isNotBlank();
            }
        }

        assertThat(statuses).contains(429);
    }

    @Test
    void theRateLimiter429IsReadableByAnAllowedOrigin() throws Exception {
        var rejected = loginUntil429("192.0.2.51", "http://localhost:5000");

        assertThat(rejected.getHeader("Access-Control-Allow-Origin")).isEqualTo("http://localhost:5000");
        assertThat(rejected.getHeader("Access-Control-Expose-Headers")).isEqualTo("Retry-After");
        assertThat(rejected.getHeader("Retry-After")).isNotBlank();
    }

    @Test
    void theRateLimiter429OfAnotherOriginHasNoAllowOrigin() throws Exception {
        var rejected = loginUntil429("192.0.2.52", "https://evil.example");

        assertThat(rejected.getHeader("Access-Control-Allow-Origin")).isNull();
    }

    @Test
    void preflightStillWorksForAnAuthPath() throws Exception {
        mvc.perform(options("/api/v1/auth/login")
                        .header("Origin", "http://localhost:5000")
                        .header("Access-Control-Request-Method", "POST")
                        .header("Access-Control-Request-Headers", "content-type"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:5000"));
    }

    // Five calls against a limit of 2: even across a minute boundary one minute goes over.
    private MockHttpServletResponse loginUntil429(String ip, String origin) throws Exception {
        for (int i = 0; i < 5; i++) {
            var response = mvc.perform(
                            post("/api/v1/auth/login").header("Origin", origin).with(request -> {
                                request.setRemoteAddr(ip);
                                return request;
                            }))
                    .andReturn()
                    .getResponse();
            if (response.getStatus() == 429) {
                return response;
            }
        }
        throw new AssertionError("No 429 after 5 sign-in calls");
    }
}
