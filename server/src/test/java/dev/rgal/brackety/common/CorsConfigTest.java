package dev.rgal.brackety.common;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalStateException;
import static org.assertj.core.api.Assertions.assertThatNoException;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;

import dev.rgal.brackety.auth.SecurityConfig;
import dev.rgal.brackety.auth.account.AccountRepository;
import java.time.Clock;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

// No CORS_ALLOWED_ORIGINS, as in a production .env left empty: no origin may be allowed.
@WebMvcTest(InfoController.class)
@Import({CorsConfigTest.SystemClock.class, SecurityConfig.class})
class CorsConfigTest {

    // The JWT decoder of SecurityConfig needs it; this slice has no JPA and no request carries a token.
    @MockitoBean
    AccountRepository accounts;

    @Autowired
    MockMvc mvc;

    @Test
    void allowsNoOriginByDefault() throws Exception {
        mvc.perform(options("/api/v1/info")
                        .header("Origin", "http://localhost:5000")
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(header().doesNotExist("Access-Control-Allow-Origin"));
    }

    @ParameterizedTest
    @ValueSource(strings = {"*", "https://*", "https://*.example.com"})
    void rejectsAnyHostWildcard(String pattern) {
        assertThatIllegalStateException().isThrownBy(() -> new CorsConfig(List.of(pattern)));
    }

    @Test
    void acceptsTheLocalNetworkPatterns() {
        assertThatNoException()
                .isThrownBy(() -> new CorsConfig(List.of("http://localhost:[*]", "http://192.168.*.*:[*]")));
    }

    @Test
    void exposesTheHeadersTheAppReads() {
        var config = new CorsConfig(List.of("https://brackety.example.test"))
                .corsConfigurationSource()
                .getCorsConfigurations()
                .get("/**");

        assertThat(config.getExposedHeaders()).containsExactly("Retry-After", "Content-Disposition");
    }

    @TestConfiguration(proxyBeanMethods = false)
    static class SystemClock {

        @Bean
        Clock clock() {
            return Clock.systemUTC();
        }
    }
}
