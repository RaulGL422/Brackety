package dev.rgal.brackety.common;

import java.time.Duration;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

// One source for Spring Security's CORS filter (found by the bean name) and for the rate limiter's 429.
@Configuration(proxyBeanMethods = false)
class CorsConfig {

    private final List<String> allowedOriginPatterns;

    CorsConfig(@Value("${brackety.cors.allowed-origin-patterns}") List<String> allowedOriginPatterns) {
        this.allowedOriginPatterns =
                allowedOriginPatterns.stream().filter(p -> !p.isBlank()).toList();
        // With credentials allowed, a wildcard host would let any website call the API as the user.
        for (var pattern : this.allowedOriginPatterns) {
            if (pattern.equals("*") || pattern.contains("://*")) {
                throw new IllegalStateException("CORS_ALLOWED_ORIGINS must not allow any host: " + pattern);
            }
        }
    }

    @Bean
    UrlBasedCorsConfigurationSource corsConfigurationSource() {
        var source = new UrlBasedCorsConfigurationSource();
        if (allowedOriginPatterns.isEmpty()) {
            return source;
        }
        var config = new CorsConfiguration();
        config.setAllowedOriginPatterns(allowedOriginPatterns);
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of(CorsConfiguration.ALL));
        // The app reads it to tell the user when to try again after a 429.
        config.setExposedHeaders(List.of(HttpHeaders.RETRY_AFTER));
        // The web app sends the refresh cookie to /api/v1/auth from its own origin.
        config.setAllowCredentials(true);
        config.setMaxAge(Duration.ofMinutes(30));
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
