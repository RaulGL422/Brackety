package dev.rgal.brackety.common;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;

import dev.rgal.brackety.auth.SecurityConfig;
import java.time.Clock;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

// No CORS_ALLOWED_ORIGINS, as in a production .env left empty: no origin may be allowed.
@WebMvcTest(InfoController.class)
@Import({CorsConfigTest.SystemClock.class, SecurityConfig.class})
class CorsConfigTest {

    @Autowired
    MockMvc mvc;

    @Test
    void allowsNoOriginByDefault() throws Exception {
        mvc.perform(options("/api/v1/info")
                        .header("Origin", "http://localhost:5000")
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(header().doesNotExist("Access-Control-Allow-Origin"));
    }

    @TestConfiguration(proxyBeanMethods = false)
    static class SystemClock {

        @Bean
        Clock clock() {
            return Clock.systemUTC();
        }
    }
}
