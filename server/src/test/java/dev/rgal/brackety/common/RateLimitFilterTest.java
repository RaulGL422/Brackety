package dev.rgal.brackety.common;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class RateLimitFilterTest {

    private static final String IP = "203.0.113.10";

    // 40 s into the minute, so Retry-After is 20.
    private final MutableClock clock = new MutableClock(Instant.parse("2027-03-10T09:00:40Z"), ZoneId.of("UTC"));
    private final RateLimitFilter filter = new RateLimitFilter(clock, 300, 20, 30);

    @Test
    void allows300RequestsPerMinuteAcrossTheApi() throws Exception {
        for (int i = 0; i < 300; i++) {
            assertThat(call("/api/v1/info", IP).getStatus()).isEqualTo(200);
        }

        var rejected = call("/api/v1/info", IP);

        assertThat(rejected.getStatus()).isEqualTo(429);
        assertThat(rejected.getHeader(HttpHeaders.RETRY_AFTER)).isEqualTo("20");
        assertThat(rejected.getContentType()).isEqualTo(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
        assertThat(rejected.getContentAsString()).contains("\"status\":429");
    }

    @Test
    void allows20RequestsPerMinuteOnAuth() throws Exception {
        for (int i = 0; i < 20; i++) {
            assertThat(call("/api/v1/auth/login", IP).getStatus()).isEqualTo(200);
        }

        assertThat(call("/api/v1/auth/login", IP).getStatus()).isEqualTo(429);
        assertThat(call("/api/v1/info", IP).getStatus()).isEqualTo(200);
    }

    @Test
    void anEncodedAuthPathCountsAsAuth() throws Exception {
        for (int i = 0; i < 20; i++) {
            call("/api/v1/auth/login", IP);
        }

        assertThat(call("/api/v1/%61uth/login", IP).getStatus()).isEqualTo(429);
    }

    @Test
    void refreshHasItsOwnLimit() throws Exception {
        for (int i = 0; i < 20; i++) {
            call("/api/v1/auth/login", IP);
        }

        for (int i = 0; i < 30; i++) {
            assertThat(call("/api/v1/auth/refresh", IP).getStatus()).isEqualTo(200);
        }
        assertThat(call("/api/v1/auth/refresh", IP).getStatus()).isEqualTo(429);
    }

    @Test
    void countsEachIpApart() throws Exception {
        for (int i = 0; i < 20; i++) {
            call("/api/v1/auth/login", IP);
        }

        assertThat(call("/api/v1/auth/login", "198.51.100.7").getStatus()).isEqualTo(200);
    }

    @Test
    void startsAgainOnTheNextMinute() throws Exception {
        for (int i = 0; i < 21; i++) {
            call("/api/v1/auth/login", IP);
        }

        clock.advance(Duration.ofSeconds(20));

        assertThat(call("/api/v1/auth/login", IP).getStatus()).isEqualTo(200);
    }

    @Test
    void neverLimitsTheHealthCheck() throws Exception {
        for (int i = 0; i < 400; i++) {
            assertThat(call("/actuator/health", IP).getStatus()).isEqualTo(200);
        }
    }

    private MockHttpServletResponse call(String path, String ip) throws Exception {
        var request = new MockHttpServletRequest("GET", path);
        request.setRemoteAddr(ip);
        var response = new MockHttpServletResponse();
        filter.doFilter(request, response, new MockFilterChain());
        return response;
    }
}
