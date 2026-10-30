package dev.rgal.brackety.auth;

import com.nimbusds.jose.jwk.source.ImmutableSecret;
import dev.rgal.brackety.auth.session.SessionService;
import dev.rgal.brackety.common.ProblemResponses;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Duration;
import java.util.List;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.crypto.argon2.Argon2PasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtClaimValidator;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtTimestampValidator;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.web.BearerTokenAuthenticationEntryPoint;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.access.AccessDeniedHandler;

@Configuration(proxyBeanMethods = false)
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    /** Granted when the access token says the email is verified; see {@link RequiresVerifiedEmail}. */
    public static final String EMAIL_VERIFIED = "EMAIL_VERIFIED";

    static final String[] PUBLIC_PATHS = {"/api/v1/auth/**", "/api/v1/info", "/actuator/health", "/error"};

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        var bearer = new BearerTokenAuthenticationEntryPoint();
        // Keeps the WWW-Authenticate header from Spring and adds the problem+json body the API uses.
        AuthenticationEntryPoint unauthorized = (request, response, e) -> {
            bearer.commence(request, response, e);
            ProblemResponses.write(response, HttpStatus.UNAUTHORIZED, "Authentication required.");
        };
        AccessDeniedHandler forbidden =
                (request, response, e) -> ProblemResponses.write(response, HttpStatus.FORBIDDEN, "Not allowed.");
        // CSRF is off because the API is stateless; the only cookie (refresh) is SameSite=Strict.
        return http.csrf(AbstractHttpConfigurer::disable)
                .cors(Customizer.withDefaults())
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(a ->
                        a.requestMatchers(PUBLIC_PATHS).permitAll().anyRequest().authenticated())
                .exceptionHandling(e -> e.authenticationEntryPoint(unauthorized).accessDeniedHandler(forbidden))
                .oauth2ResourceServer(o -> o.jwt(j -> j.jwtAuthenticationConverter(jwtAuthenticationConverter()))
                        .authenticationEntryPoint(unauthorized)
                        .accessDeniedHandler(forbidden))
                .build();
    }

    private static JwtAuthenticationConverter jwtAuthenticationConverter() {
        var converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(
                jwt -> Boolean.TRUE.equals(jwt.getClaimAsBoolean(SessionService.EMAIL_VERIFIED_CLAIM))
                        ? List.of(new SimpleGrantedAuthority(EMAIL_VERIFIED))
                        : List.of());
        return converter;
    }

    @Bean
    SecretKey jwtKey(@Value("${brackety.auth.jwt-secret}") String secret) {
        var bytes = secret.getBytes(StandardCharsets.UTF_8);
        if (bytes.length < 32) {
            throw new IllegalStateException("JWT_SECRET must be at least 32 bytes long");
        }
        return new SecretKeySpec(bytes, "HmacSHA256");
    }

    @Bean
    JwtEncoder jwtEncoder(SecretKey jwtKey) {
        return new NimbusJwtEncoder(new ImmutableSecret<>(jwtKey));
    }

    @Bean
    JwtDecoder jwtDecoder(SecretKey jwtKey, Clock clock) {
        var decoder = NimbusJwtDecoder.withSecretKey(jwtKey)
                .macAlgorithm(MacAlgorithm.HS256)
                .build();
        // No clock skew: this server both issues and checks the tokens with the same clock.
        var timestamps = new JwtTimestampValidator(Duration.ZERO);
        timestamps.setClock(clock);
        // Only access tokens: a reauth or restore token, signed with the same key, must not open the API.
        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
                timestamps,
                new JwtClaimValidator<String>(SessionService.PURPOSE_CLAIM, SessionService.ACCESS_PURPOSE::equals)));
        return decoder;
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        // Argon2id with the OWASP minimum: 19 MiB of memory, 2 iterations, 1 thread.
        return new Argon2PasswordEncoder(16, 32, 1, 19 * 1024, 2);
    }
}
