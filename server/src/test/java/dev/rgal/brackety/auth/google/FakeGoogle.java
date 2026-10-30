package dev.rgal.brackety.auth.google;

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

/** Stands in for Google in tests and the local runner: its own RSA key, published as the JWKS. */
public class FakeGoogle {

    public static final String CLIENT_ID = "brackety-test.apps.googleusercontent.com";

    private final RSAKey key = newKey("fake-google");
    private final Clock clock;

    public FakeGoogle(Clock clock) {
        this.clock = clock;
    }

    public JWKSource<SecurityContext> jwks() {
        return new ImmutableJWKSet<>(new JWKSet(key.toPublicJWK()));
    }

    /** A valid ID token, as Google would issue it now for this person. */
    public String idToken(String subject, String email) {
        return sign(claims(subject, email).build());
    }

    public JWTClaimsSet.Builder claims(String subject, String email) {
        var now = clock.instant();
        return new JWTClaimsSet.Builder()
                .issuer("https://accounts.google.com")
                .audience(CLIENT_ID)
                .subject(subject)
                .claim("email", email)
                .claim("email_verified", true)
                .issueTime(Date.from(now))
                .expirationTime(Date.from(now.plus(Duration.ofHours(1))));
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
