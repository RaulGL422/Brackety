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
import org.springframework.stereotype.Component;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.CorsProcessor;
import org.springframework.web.cors.CorsUtils;
import org.springframework.web.cors.DefaultCorsProcessor;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.UrlPathHelper;

// Requests per IP per clock minute, in memory: the API runs as a single instance.
// Runs before Spring Security so a flood is cut before any token or password work. Being ahead of
// Security's CORS filter, it adds the CORS headers to its own 429: without them the browser hides it.
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
class RateLimitFilter extends OncePerRequestFilter {

    static final String AUTH_PATH = "/api/v1/auth/";
    // Refresh needs a valid token, so it gets its own, higher limit: many users share one IP at an event.
    static final String REFRESH_PATH = "/api/v1/auth/refresh";
    // The superadmin login guesses passwords like any other: same limit as sign-in.
    static final String ADMIN_LOGIN_PATH = "/api/v1/admin/auth/login";
    static final String HEALTH_PATH = "/actuator/health";
    // Decoded path, as Spring MVC matches it: the raw URI would let /api/v1/%61uth skip the auth limit.
    private static final UrlPathHelper PATHS = UrlPathHelper.defaultInstance;
    private static final CorsProcessor CORS = new DefaultCorsProcessor();

    private final Clock clock;
    private final CorsConfigurationSource cors;
    private final MinuteCounter all;
    private final MinuteCounter auth;
    private final MinuteCounter refresh;

    RateLimitFilter(
            Clock clock,
            CorsConfigurationSource corsConfigurationSource,
            @Value("${brackety.rate-limit.per-minute}") int perMinute,
            @Value("${brackety.rate-limit.auth-per-minute}") int authPerMinute,
            @Value("${brackety.rate-limit.refresh-per-minute}") int refreshPerMinute) {
        this.clock = clock;
        this.cors = corsConfigurationSource;
        this.all = new MinuteCounter(perMinute);
        this.auth = new MinuteCounter(authPerMinute);
        this.refresh = new MinuteCounter(refreshPerMinute);
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return PATHS.getPathWithinApplication(request).startsWith(HEALTH_PATH);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        var epochSecond = clock.instant().getEpochSecond();
        var minute = epochSecond / 60;
        var ip = request.getRemoteAddr();
        // A preflight does no token or password work, so it only counts toward the general limit: the sign-in
        // limit stays per real attempt, and its 429 lands on the request the app can read.
        var allowed = all.tryAcquire(ip, minute)
                && (CorsUtils.isPreFlightRequest(request)
                        || limitFor(PATHS.getPathWithinApplication(request), ip, minute));
        if (allowed) {
            chain.doFilter(request, response);
            return;
        }
        if (addCorsHeaders(request, response)) {
            response.setHeader(HttpHeaders.RETRY_AFTER, String.valueOf(60 - epochSecond % 60));
            ProblemResponses.write(response, HttpStatus.TOO_MANY_REQUESTS, "Too many requests. Try again later.");
        }
    }

    // Only for an allowed origin: Spring answers any other with a 403, and a flood must keep getting its 429.
    // False when Spring still rejected the request (e.g. a method CORS does not allow) and wrote its 403.
    private boolean addCorsHeaders(HttpServletRequest request, HttpServletResponse response) throws IOException {
        var config = cors.getCorsConfiguration(request);
        if (config == null || config.checkOrigin(request.getHeader(HttpHeaders.ORIGIN)) == null) {
            return true;
        }
        return CORS.processRequest(config, request, response);
    }

    private boolean limitFor(String path, String ip, long minute) {
        if (path.startsWith(REFRESH_PATH)) {
            return refresh.tryAcquire(ip, minute);
        }
        var signIn = path.startsWith(AUTH_PATH) || path.startsWith(ADMIN_LOGIN_PATH);
        return !signIn || auth.tryAcquire(ip, minute);
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
