package dev.rgal.brackety.auth.session;

import java.time.Clock;
import java.time.Duration;
import java.util.Optional;
import java.util.UUID;
import javax.crypto.SecretKey;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.JwtTimestampValidator;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.stereotype.Component;

/**
 * Signed like the access token, but its purpose claim differs: neither is accepted where the other is expected.
 * Nothing is stored, so they cannot be revoked; hence the short life.
 */
@Component
public class ShortLivedTokens {

    public static final Duration TTL = Duration.ofMinutes(5);

    public enum Purpose {
        /** Proves the password or Google again, for a sensitive action. */
        REAUTH,
        /** Lets the owner of a deleted account, who just proved it is theirs, cancel the deletion. */
        RESTORE
    }

    private final JwtEncoder encoder;
    private final JwtDecoder decoder;
    private final Clock clock;

    ShortLivedTokens(JwtEncoder encoder, SecretKey jwtKey, Clock clock) {
        this.encoder = encoder;
        this.clock = clock;
        var decoder = NimbusJwtDecoder.withSecretKey(jwtKey)
                .macAlgorithm(MacAlgorithm.HS256)
                .build();
        var timestamps = new JwtTimestampValidator(Duration.ZERO);
        timestamps.setClock(clock);
        decoder.setJwtValidator(timestamps);
        this.decoder = decoder;
    }

    public String issue(UUID accountId, Purpose purpose) {
        var now = clock.instant();
        var claims = JwtClaimsSet.builder()
                .subject(accountId.toString())
                .issuedAt(now)
                .expiresAt(now.plus(TTL))
                .claim(SessionService.PURPOSE_CLAIM, purpose.name())
                .build();
        var header = JwsHeader.with(MacAlgorithm.HS256).build();
        return encoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
    }

    /** The account the token was issued to; empty if it is invalid, expired or for another purpose. */
    public Optional<UUID> verify(String token, Purpose purpose) {
        if (token == null || token.isBlank()) {
            return Optional.empty();
        }
        try {
            var jwt = decoder.decode(token);
            if (!purpose.name().equals(jwt.getClaimAsString(SessionService.PURPOSE_CLAIM))) {
                return Optional.empty();
            }
            return Optional.of(UUID.fromString(jwt.getSubject()));
        } catch (JwtException | IllegalArgumentException e) {
            return Optional.empty();
        }
    }
}
