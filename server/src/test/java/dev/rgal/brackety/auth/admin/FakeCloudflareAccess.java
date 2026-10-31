package dev.rgal.brackety.auth.admin;

import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JOSEObjectType;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.RSASSASigner;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.gen.RSAKeyGenerator;
import com.nimbusds.jose.jwk.source.ImmutableJWKSet;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.proc.SecurityContext;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import java.time.Clock;
import java.time.Duration;
import java.util.Date;

/** Stands in for Cloudflare Access in tests: its own RSA key, published as the team JWKS. */
public class FakeCloudflareAccess {

    public static final String TEAM_DOMAIN = "brackety-test.cloudflareaccess.com";
    public static final String AUDIENCE = "test-access-aud";

    private final RSAKey key = newKey("fake-cloudflare");
    private final Clock clock;

    public FakeCloudflareAccess(Clock clock) {
        this.clock = clock;
    }

    public JWKSource<SecurityContext> jwks() {
        return new ImmutableJWKSet<>(new JWKSet(key.toPublicJWK()));
    }

    public CloudflareAccess access() {
        return CloudflareAccess.of(jwks(), TEAM_DOMAIN, AUDIENCE, clock);
    }

    /** What Cloudflare puts in Cf-Access-Jwt-Assertion for a user that just passed the Access login. */
    public String assertion() {
        return sign(claims().build());
    }

    public JWTClaimsSet.Builder claims() {
        var now = clock.instant();
        return new JWTClaimsSet.Builder()
                .issuer("https://" + TEAM_DOMAIN)
                .audience(AUDIENCE)
                .subject("cloudflare-user-id")
                .claim("type", "app")
                .issueTime(Date.from(now))
                .expirationTime(Date.from(now.plus(Duration.ofHours(24))));
    }

    public String sign(JWTClaimsSet claims) {
        return sign(claims, key);
    }

    static String sign(JWTClaimsSet claims, RSAKey signingKey) {
        var header = new JWSHeader.Builder(JWSAlgorithm.RS256)
                .type(JOSEObjectType.JWT)
                .keyID(signingKey.getKeyID())
                .build();
        var jwt = new SignedJWT(header, claims);
        try {
            jwt.sign(new RSASSASigner(signingKey));
        } catch (JOSEException e) {
            throw new IllegalStateException(e);
        }
        return jwt.serialize();
    }

    static RSAKey newKey(String keyId) {
        try {
            return new RSAKeyGenerator(2048).keyID(keyId).generate();
        } catch (JOSEException e) {
            throw new IllegalStateException(e);
        }
    }
}
