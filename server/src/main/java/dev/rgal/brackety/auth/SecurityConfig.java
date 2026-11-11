package dev.rgal.brackety.auth;

import com.nimbusds.jose.jwk.source.ImmutableSecret;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.jwk.source.JWKSourceBuilder;
import com.nimbusds.jose.proc.SecurityContext;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.admin.AdminAuthService;
import dev.rgal.brackety.auth.admin.CloudflareAccess;
import dev.rgal.brackety.auth.admin.CloudflareAccessFilter;
import dev.rgal.brackety.auth.session.SessionService;
import dev.rgal.brackety.common.ProblemResponses;
import java.net.MalformedURLException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Duration;
import java.util.List;
import java.util.UUID;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
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
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2ErrorCodes;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtClaimNames;
import org.springframework.security.oauth2.jwt.JwtClaimValidator;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtTimestampValidator;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.web.BearerTokenAuthenticationEntryPoint;
import org.springframework.security.oauth2.server.resource.web.authentication.BearerTokenAuthenticationFilter;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.access.AccessDeniedHandler;

@Configuration(proxyBeanMethods = false)
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    /** Granted when the access token says the email is verified; see {@link RequiresVerifiedEmail}. */
    public static final String EMAIL_VERIFIED = "EMAIL_VERIFIED";

    static final String ADMIN_PATHS = "/api/v1/admin/**";
    static final String ADMIN_LOGIN_PATH = "/api/v1/admin/auth/login";
    static final String[] PUBLIC_PATHS = {
        "/api/v1/auth/**", "/api/v1/info", "/api/v1/legal/**", "/actuator/health", "/error"
    };

    // The superadmin API: its own token (purpose ADMIN) and, ahead of everything, Cloudflare Access.
    @Bean
    @Order(1)
    SecurityFilterChain adminFilterChain(
            HttpSecurity http,
            SecretKey jwtKey,
            Clock clock,
            CloudflareAccess cloudflareAccess,
            @Value("${brackety.admin.local-only:false}") boolean localOnly)
            throws Exception {
        return http.securityMatcher(ADMIN_PATHS)
                .csrf(AbstractHttpConfigurer::disable)
                .cors(Customizer.withDefaults())
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .addFilterBefore(new CloudflareAccessFilter(cloudflareAccess, localOnly), BearerTokenAuthenticationFilter.class)
                .authorizeHttpRequests(a -> a.requestMatchers(ADMIN_LOGIN_PATH)
                        .permitAll()
                        .anyRequest()
                        .authenticated())
                .exceptionHandling(
                        e -> e.authenticationEntryPoint(unauthorized()).accessDeniedHandler(forbidden()))
                .oauth2ResourceServer(o -> o.jwt(j -> j.decoder(adminJwtDecoder(jwtKey, clock)))
                        .authenticationEntryPoint(unauthorized())
                        .accessDeniedHandler(forbidden()))
                .build();
    }

    @Bean
    @Order(2)
    SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        // CSRF is off because the API is stateless; the only cookie (refresh) is SameSite=Strict.
        return http.csrf(AbstractHttpConfigurer::disable)
                .cors(Customizer.withDefaults())
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(a ->
                        a.requestMatchers(PUBLIC_PATHS).permitAll().anyRequest().authenticated())
                .exceptionHandling(
                        e -> e.authenticationEntryPoint(unauthorized()).accessDeniedHandler(forbidden()))
                .oauth2ResourceServer(o -> o.jwt(j -> j.jwtAuthenticationConverter(jwtAuthenticationConverter()))
                        .authenticationEntryPoint(unauthorized())
                        .accessDeniedHandler(forbidden()))
                .build();
    }

    // Keeps the WWW-Authenticate header from Spring and adds the problem+json body the API uses.
    private static AuthenticationEntryPoint unauthorized() {
        var bearer = new BearerTokenAuthenticationEntryPoint();
        return (request, response, e) -> {
            bearer.commence(request, response, e);
            ProblemResponses.write(response, HttpStatus.UNAUTHORIZED, "Authentication required.");
        };
    }

    private static AccessDeniedHandler forbidden() {
        return (request, response, e) -> ProblemResponses.write(response, HttpStatus.FORBIDDEN, "Not allowed.");
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
    JwtDecoder jwtDecoder(SecretKey jwtKey, Clock clock, AccountRepository accounts) {
        var decoder = NimbusJwtDecoder.withSecretKey(jwtKey)
                .macAlgorithm(MacAlgorithm.HS256)
                .build();
        // No clock skew: this server both issues and checks the tokens with the same clock.
        var timestamps = new JwtTimestampValidator(Duration.ZERO);
        timestamps.setClock(clock);
        // Only access tokens: a reauth or restore token, signed with the same key, must not open the API.
        // In order and stopping at the first failure: the session check reads the account by a UUID subject, which
        // only an access token has (the superadmin token says "superadmin" and must be a 401, not a 500).
        decoder.setJwtValidator(firstFailure(
                timestamps,
                new JwtClaimValidator<String>(SessionService.PURPOSE_CLAIM, SessionService.ACCESS_PURPOSE::equals),
                liveSession(accounts)));
        return decoder;
    }

    @SafeVarargs
    private static OAuth2TokenValidator<Jwt> firstFailure(OAuth2TokenValidator<Jwt>... validators) {
        return jwt -> {
            for (var validator : validators) {
                var result = validator.validate(jwt);
                if (result.hasErrors()) {
                    return result;
                }
            }
            return OAuth2TokenValidatorResult.success();
        };
    }

    // One read per request: a deleted account, or a token issued before a password reset, an email change
    // or a deletion, must not keep its 15 minutes.
    private static OAuth2TokenValidator<Jwt> liveSession(AccountRepository accounts) {
        var closed = OAuth2TokenValidatorResult.failure(
                new OAuth2Error(OAuth2ErrorCodes.INVALID_TOKEN, "The session has been closed.", null));
        return jwt -> accounts.findById(UUID.fromString(jwt.getSubject()))
                        .filter(a -> a.acceptsTokenIssuedAt(jwt.getIssuedAt()))
                        .isPresent()
                ? OAuth2TokenValidatorResult.success()
                : closed;
    }

    // Not a bean: a second JwtDecoder bean would confuse the user chain. No refresh and no revocation: it lasts
    // one hour, and changing the superadmin password means a restart anyway.
    private static JwtDecoder adminJwtDecoder(SecretKey jwtKey, Clock clock) {
        var decoder = NimbusJwtDecoder.withSecretKey(jwtKey)
                .macAlgorithm(MacAlgorithm.HS256)
                .build();
        var timestamps = new JwtTimestampValidator(Duration.ZERO);
        timestamps.setClock(clock);
        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
                timestamps,
                new JwtClaimValidator<String>(SessionService.PURPOSE_CLAIM, AdminAuthService.ADMIN_PURPOSE::equals),
                new JwtClaimValidator<String>(JwtClaimNames.SUB, AdminAuthService.SUBJECT::equals)));
        return decoder;
    }

    // Cloudflare's keys are fetched on first use and cached. Tests and the local runner replace this bean.
    @Bean
    CloudflareAccess cloudflareAccess(
            @Value("${brackety.admin.cloudflare-access.team-domain:}") String teamDomain,
            @Value("${brackety.admin.cloudflare-access.audience:}") String audience,
            Clock clock)
            throws MalformedURLException {
        JWKSource<SecurityContext> keys = teamDomain.isBlank()
                ? null
                : JWKSourceBuilder.<SecurityContext>create(URI.create(CloudflareAccess.certsUrl(teamDomain))
                                .toURL())
                        .build();
        return CloudflareAccess.of(keys, teamDomain, audience, clock);
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        // Argon2id with the OWASP minimum: 19 MiB of memory, 2 iterations, 1 thread.
        return new Argon2PasswordEncoder(16, 32, 1, 19 * 1024, 2);
    }
}
