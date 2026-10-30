package dev.rgal.brackety.common;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.Clock;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

// Requests per IP per clock minute, in memory: the API runs as a single instance.
// Runs before Spring Security so a flood is cut before any token or password work.
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
class RateLimitFilter extends OncePerRequestFilter {

    static final String AUTH_PATH = "/api/v1/auth/";
    static final String HEALTH_PATH = "/actuator/health";

    private final Clock clock;
    private final MinuteCounter all;
    private final MinuteCounter auth;

    RateLimitFilter(
            Clock clock,
            @Value("${brackety.rate-limit.per-minute:300}") int perMinute,
            @Value("${brackety.rate-limit.auth-per-minute:20}") int authPerMinute) {
        this.clock = clock;
        this.all = new MinuteCounter(perMinute);
        this.auth = new MinuteCounter(authPerMinute);
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return request.getRequestURI().startsWith(HEALTH_PATH);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        var epochSecond = clock.instant().getEpochSecond();
        var minute = epochSecond / 60;
        var ip = request.getRemoteAddr();
        var allowed = all.tryAcquire(ip, minute)
                && (!request.getRequestURI().startsWith(AUTH_PATH) || auth.tryAcquire(ip, minute));
        if (allowed) {
            chain.doFilter(request, response);
            return;
        }
        response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
        response.setHeader(HttpHeaders.RETRY_AFTER, String.valueOf(60 - epochSecond % 60));
        response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
        response.getWriter()
                .write("{\"type\":\"about:blank\",\"title\":\"Too Many Requests\",\"status\":429,"
                        + "\"detail\":\"Too many requests. Try again later.\"}");
    }

    // A fresh map every minute: memory is bounded by the IPs seen in one minute.
    private static final class MinuteCounter {

        private final int limit;
        private long minute = -1;
        private Map<String, AtomicInteger> counts = new ConcurrentHashMap<>();

        MinuteCounter(int limit) {
            this.limit = limit;
        }

        boolean tryAcquire(String ip, long currentMinute) {
            Map<String, AtomicInteger> current;
            synchronized (this) {
                if (currentMinute != minute) {
                    minute = currentMinute;
                    counts = new ConcurrentHashMap<>();
                }
                current = counts;
            }
            return current.computeIfAbsent(ip, k -> new AtomicInteger()).incrementAndGet() <= limit;
        }
    }
}
