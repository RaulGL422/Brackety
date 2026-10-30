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

    public CloudflareAccessFilter(CloudflareAccess access) {
        this.access = access;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        switch (access.check(request.getHeader(CloudflareAccess.HEADER))) {
            case ALLOWED -> chain.doFilter(request, response);
            case DENIED -> ProblemResponses.write(response, HttpStatus.FORBIDDEN, "Cloudflare Access required.");
            case UNAVAILABLE ->
                ProblemResponses.write(
                        response, HttpStatus.SERVICE_UNAVAILABLE, "The superadmin API is not available right now.");
        }
    }
}
