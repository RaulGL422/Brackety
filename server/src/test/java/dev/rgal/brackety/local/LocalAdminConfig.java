package dev.rgal.brackety.local;

import dev.rgal.brackety.auth.admin.CloudflareAccess;
import dev.rgal.brackety.auth.admin.FakeCloudflareAccess;
import jakarta.servlet.Filter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import java.time.Clock;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.core.Ordered;

// Cloudflare Access without Cloudflare, as LocalGoogleConfig does for Google: the local API runs the real Access
// check against a key made at startup, and a filter signs the assertion Cloudflare would add, so the admin app
// works locally with no extra step. Lives in test sources, so neither the key nor the filter reach production.
@TestConfiguration(proxyBeanMethods = false)
class LocalAdminConfig {

    static final String ADMIN_PATH = "/api/v1/admin/";

    @Bean
    FakeCloudflareAccess localCloudflare(Clock clock) {
        return new FakeCloudflareAccess(clock);
    }

    @Bean
    @Primary
    CloudflareAccess localCloudflareAccess(FakeCloudflareAccess cloudflare) {
        return cloudflare.access();
    }

    // Runs before Spring Security, where the check is. Only fills the header when the request has none.
    @Bean
    FilterRegistrationBean<Filter> localAccessAssertion(FakeCloudflareAccess cloudflare) {
        Filter filter = (request, response, chain) -> {
            var http = (HttpServletRequest) request;
            var needsAssertion =
                    http.getRequestURI().startsWith(ADMIN_PATH) && http.getHeader(CloudflareAccess.HEADER) == null;
            chain.doFilter(needsAssertion ? withAssertion(http, cloudflare.assertion()) : request, response);
        };
        var registration = new FilterRegistrationBean<>(filter);
        registration.setOrder(Ordered.HIGHEST_PRECEDENCE + 10);
        return registration;
    }

    private static HttpServletRequest withAssertion(HttpServletRequest request, String assertion) {
        return new HttpServletRequestWrapper(request) {
            @Override
            public String getHeader(String name) {
                return CloudflareAccess.HEADER.equalsIgnoreCase(name) ? assertion : super.getHeader(name);
            }
        };
    }
}
