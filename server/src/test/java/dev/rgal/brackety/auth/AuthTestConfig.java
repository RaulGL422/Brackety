package dev.rgal.brackety.auth;

import dev.rgal.brackety.local.EmbeddedPostgresConfig;
import java.time.Instant;
import java.time.ZoneId;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

// Shared by every auth test so they reuse one Spring context and one embedded database.
@TestConfiguration(proxyBeanMethods = false)
@Import({EmbeddedPostgresConfig.class, AuthTestConfig.ProtectedController.class})
class AuthTestConfig {

    static final Instant START = Instant.parse("2027-03-10T09:00:00Z");

    @Bean
    @Primary
    MutableClock testClock() {
        return new MutableClock(START, ZoneId.of("Europe/Madrid"));
    }

    // No real protected endpoint exists yet; this one stands in for them.
    @RestController
    static class ProtectedController {

        @GetMapping("/api/v1/test/whoami")
        String whoami(@AuthenticationPrincipal Jwt jwt) {
            return jwt.getSubject() + " " + jwt.getClaimAsStringList("profiles");
        }
    }
}
