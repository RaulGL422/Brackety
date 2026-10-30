package dev.rgal.brackety.local;

import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.proc.SecurityContext;
import dev.rgal.brackety.auth.google.FakeGoogle;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import java.time.Clock;
import java.util.Map;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

// Google sign-in without Google: the local API trusts a key made at startup and hands out ID tokens for any
// subject and email. Lives in test sources, so it never reaches the production jar.
@TestConfiguration(proxyBeanMethods = false)
@Import(LocalGoogleConfig.DevGoogleTokenController.class)
class LocalGoogleConfig {

    @Bean
    FakeGoogle fakeGoogle(Clock clock) {
        return new FakeGoogle(clock);
    }

    @Bean
    @Primary
    JWKSource<SecurityContext> localGoogleJwks(FakeGoogle google) {
        return google.jwks();
    }

    @RestController
    static class DevGoogleTokenController {

        private final FakeGoogle google;

        DevGoogleTokenController(FakeGoogle google) {
            this.google = google;
        }

        @PostMapping("/api/v1/auth/dev/google-token")
        Map<String, String> idToken(@Valid @RequestBody DevGoogleTokenRequest request) {
            return Map.of("idToken", google.idToken(request.subject(), request.email()));
        }
    }

    record DevGoogleTokenRequest(
            @NotBlank String subject, @NotBlank String email) {}
}
