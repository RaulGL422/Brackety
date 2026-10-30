package dev.rgal.brackety.auth.google;

import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.proc.SecurityContext;
import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.account.Account;
import java.time.Clock;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.jose.jws.SignatureAlgorithm;
import org.springframework.security.oauth2.jwt.BadJwtException;
import org.springframework.security.oauth2.jwt.JwtClaimNames;
import org.springframework.security.oauth2.jwt.JwtClaimValidator;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.JwtTimestampValidator;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.stereotype.Component;

/** Checks the ID token the app got from Google, as Google documents it. */
@Component
public class GoogleIdTokens {

    static final Set<String> ISSUERS = Set.of("accounts.google.com", "https://accounts.google.com");

    private static final Logger log = LoggerFactory.getLogger(GoogleIdTokens.class);

    // Null when GOOGLE_CLIENT_ID is empty: the API starts and only Google sign-in answers 503.
    private final JwtDecoder decoder;

    GoogleIdTokens(
            JWKSource<SecurityContext> googleJwks,
            @Value("${brackety.auth.google-client-ids:}") String clientIds,
            Clock clock) {
        var audiences = Arrays.stream(clientIds.split(","))
                .map(String::strip)
                .filter(id -> !id.isEmpty())
                .toList();
        this.decoder = audiences.isEmpty() ? null : decoder(googleJwks, audiences, clock);
    }

    public GoogleUser verify(String idToken) {
        if (decoder == null) {
            throw AuthException.googleNotConfigured();
        }
        try {
            var jwt = decoder.decode(idToken);
            return new GoogleUser(jwt.getSubject(), Account.normalizeEmail(jwt.getClaimAsString("email")));
        } catch (BadJwtException e) {
            throw AuthException.googleSignInFailed();
        } catch (JwtException e) {
            // Not a bad token: most likely Google's keys could not be fetched.
            log.warn("Google ID token could not be checked: {}", e.getMessage());
            throw AuthException.googleUnavailable();
        }
    }

    private static JwtDecoder decoder(JWKSource<SecurityContext> jwks, List<String> audiences, Clock clock) {
        var decoder = NimbusJwtDecoder.withJwkSource(jwks)
                .jwsAlgorithm(SignatureAlgorithm.RS256)
                .build();
        var timestamps = new JwtTimestampValidator();
        timestamps.setClock(clock);
        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
                timestamps,
                new JwtClaimValidator<>(JwtClaimNames.EXP, Objects::nonNull),
                new JwtClaimValidator<>(JwtClaimNames.ISS, iss -> iss != null && ISSUERS.contains(iss.toString())),
                new JwtClaimValidator<Collection<String>>(
                        JwtClaimNames.AUD, aud -> aud != null && aud.stream().anyMatch(audiences::contains)),
                new JwtClaimValidator<>(
                        JwtClaimNames.SUB, sub -> sub != null && !sub.toString().isBlank()),
                new JwtClaimValidator<>(
                        "email", email -> email != null && !email.toString().isBlank()),
                // Without it anyone could claim someone else's address through a Google account.
                new JwtClaimValidator<>("email_verified", v -> v != null && "true".equals(v.toString()))));
        return decoder;
    }

    /** {@code subject} is Google's stable id for the person; {@code email} is normalised. */
    public record GoogleUser(String subject, String email) {}
}
