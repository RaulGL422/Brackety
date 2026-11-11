package dev.rgal.brackety.auth.admin;

import dev.rgal.brackety.common.ProblemResponses;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.http.HttpStatus;
import org.springframework.web.filter.OncePerRequestFilter;

// Only in the superadmin filter chain, ahead of the bearer token: without Access nothing else is looked at.
// Not a bean on purpose, or Spring Boot would also run it on every request of the API.
public class CloudflareAccessFilter extends OncePerRequestFilter {

    private final CloudflareAccess access;
    private final boolean localOnly;

    /**
     * {@code localOnly}: hall mode (ADMIN_LOCAL_ONLY, docs/modulos/servidor-local.md). The laptop has no Cloudflare
     * Access, so the superadmin API answers only requests from the laptop itself (loopback), and nobody else.
     */
    public CloudflareAccessFilter(CloudflareAccess access, boolean localOnly) {
        this.access = access;
        this.localOnly = localOnly;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        if (localOnly) {
            if (isLoopback(request.getRemoteAddr())) {
                chain.doFilter(request, response);
            } else {
                ProblemResponses.write(
                        response, HttpStatus.FORBIDDEN, "The superadmin API only answers on this computer.");
            }
            return;
        }
        switch (access.check(request.getHeader(CloudflareAccess.HEADER))) {
            case ALLOWED -> chain.doFilter(request, response);
            case DENIED -> ProblemResponses.write(response, HttpStatus.FORBIDDEN, "Cloudflare Access required.");
            case UNAVAILABLE ->
                ProblemResponses.write(
                        response, HttpStatus.SERVICE_UNAVAILABLE, "The superadmin API is not available right now.");
        }
    }

    static boolean isLoopback(String address) {
        return address != null
                && (address.equals("127.0.0.1") || address.equals("::1") || address.equals("0:0:0:0:0:0:0:1"));
    }
}
