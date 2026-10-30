package dev.rgal.brackety.common;

import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration(proxyBeanMethods = false)
class CorsConfig implements WebMvcConfigurer {

    private final List<String> allowedOriginPatterns;

    CorsConfig(@Value("${brackety.cors.allowed-origin-patterns}") List<String> allowedOriginPatterns) {
        this.allowedOriginPatterns =
                allowedOriginPatterns.stream().filter(p -> !p.isBlank()).toList();
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        if (allowedOriginPatterns.isEmpty()) {
            return;
        }
        registry.addMapping("/**")
                .allowedOriginPatterns(allowedOriginPatterns.toArray(String[]::new))
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
                // The web app sends the refresh cookie to /api/v1/auth from its own origin.
                .allowCredentials(true);
    }
}
