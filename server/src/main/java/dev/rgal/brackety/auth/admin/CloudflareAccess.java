package dev.rgal.brackety.auth.admin;

import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.proc.SecurityContext;
import java.time.Clock;
import java.util.Collection;
import java.util.Objects;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.jose.jws.SignatureAlgorithm;
import org.springframework.security.oauth2.jwt.BadJwtException;
import org.springframework.security.oauth2.jwt.JwtClaimNames;
import org.springframework.security.oauth2.jwt.JwtClaimValidator;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.JwtTimestampValidator;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;

/**
 * Checks the JWT Cloudflare Access adds to every request that passed its login (header
 * {@value #HEADER}), as Cloudflare documents it. Guards the whole superadmin API, login included.
 */
public class CloudflareAccess {

    public static final String HEADER = "Cf-Access-Jwt-Assertion";

    private static final Logger log = LoggerFactory.getLogger(CloudflareAccess.class);

    public enum Outcome {
        ALLOWED,
        DENIED,
        UNAVAILABLE
    }

    // Null when the team domain or the audience is missing: the superadmin API answers 503.
    private final JwtDecoder decoder;
    private final boolean enforced;

    private CloudflareAccess(JwtDecoder decoder, boolean enforced) {
        this.decoder = decoder;
        this.enforced = enforced;
    }

    /** {@code teamDomain} as in the Zero Trust dashboard, e.g. {@code myteam.cloudflareaccess.com}. */
    public static CloudflareAccess of(
            JWKSource<SecurityContext> keys, String teamDomain, String audience, Clock clock) {
        if (keys == null || teamDomain.isBlank() || audience.isBlank()) {
            return new CloudflareAccess(null, true);
        }
        return new CloudflareAccess(decoder(keys, issuer(teamDomain), audience.strip(), clock), true);
    }

    /** Lets everything through. Only the local runner uses it (test sources); no setting reaches it. */
    public static CloudflareAccess notEnforced() {
        return new CloudflareAccess(null, false);
    }

    public Outcome check(String assertion) {
        if (!enforced) {
            return Outcome.ALLOWED;
        }
        if (decoder == null) {
            return Outcome.UNAVAILABLE;
        }
        if (assertion == null || assertion.isBlank()) {
            return Outcome.DENIED;
        }
        try {
            decoder.decode(assertion);
            return Outcome.ALLOWED;
        } catch (BadJwtException e) {
            return Outcome.DENIED;
        } catch (JwtException e) {
            // Not a bad token: most likely Cloudflare's keys could not be fetched.
            log.warn("Cloudflare Access token could not be checked: {}", e.getMessage());
            return Outcome.UNAVAILABLE;
        }
    }

    /** The JWKS address for the team: {@code https://<team domain>/cdn-cgi/access/certs}. */
    public static String certsUrl(String teamDomain) {
        return issuer(teamDomain) + "/cdn-cgi/access/certs";
    }

    // Accepts the domain with or without scheme and trailing slash, as people copy it either way.
    static String issuer(String teamDomain) {
        var domain = teamDomain.strip().replaceFirst("^https://", "");
        while (domain.endsWith("/")) {
            domain = domain.substring(0, domain.length() - 1);
        }
        return "https://" + domain;
    }

    private static JwtDecoder decoder(JWKSource<SecurityContext> keys, String issuer, String audience, Clock clock) {
        var decoder = NimbusJwtDecoder.withJwkSource(keys)
                .jwsAlgorithm(SignatureAlgorithm.RS256)
                .build();
        // 60 s of skew, as for Google: Cloudflare's clock is not ours.
        var timestamps = new JwtTimestampValidator();
        timestamps.setClock(clock);
        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
                timestamps,
                new JwtClaimValidator<>(JwtClaimNames.EXP, Objects::nonNull),
                new JwtClaimValidator<>(JwtClaimNames.ISS, iss -> iss != null && issuer.equals(iss.toString())),
                new JwtClaimValidator<Collection<String>>(
                        JwtClaimNames.AUD, aud -> aud != null && aud.contains(audience))));
        return decoder;
    }
}
