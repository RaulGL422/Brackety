package dev.rgal.brackety;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
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
import org.springframework.jdbc.core.simple.JdbcClient;
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
}
