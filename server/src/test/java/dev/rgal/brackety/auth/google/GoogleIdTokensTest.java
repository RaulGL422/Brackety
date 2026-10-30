package dev.rgal.brackety.auth.google;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.common.MutableClock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.util.function.UnaryOperator;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.http.HttpStatus;

class GoogleIdTokensTest {

    private static final String WEB_CLIENT = "web.apps.googleusercontent.com";

    private final MutableClock clock = new MutableClock(Instant.parse("2027-03-10T09:00:00Z"), ZoneId.of("UTC"));
    private final FakeGoogle google = new FakeGoogle(clock);
    private final GoogleIdTokens tokens =
            new GoogleIdTokens(google.jwks(), " " + WEB_CLIENT + " , " + FakeGoogle.CLIENT_ID + ",", clock);

    @Test
    void acceptsAValidTokenAndKeepsTheSubjectAndNormalisedEmail() {
        var user = tokens.verify(google.idToken("sub-1", "Ana@Example.test"));

        assertThat(user.subject()).isEqualTo("sub-1");
        assertThat(user.email()).isEqualTo("ana@example.test");
    }

    @ParameterizedTest
    @ValueSource(strings = {"accounts.google.com", "https://accounts.google.com"})
    void acceptsBothGoogleIssuers(String issuer) {
        assertThat(verify(c -> c.issuer(issuer)).subject()).isEqualTo("sub-1");
    }

    @Test
    void acceptsAnyConfiguredClientIdAsAudience() {
        assertThat(verify(c -> c.audience(WEB_CLIENT)).subject()).isEqualTo("sub-1");
    }

    @Test
    void acceptsTheStringFormOfEmailVerified() {
        assertThat(verify(c -> c.claim("email_verified", "true")).subject()).isEqualTo("sub-1");
    }

    @Test
    void rejectsATokenSignedWithAnotherKey() {
        var forged =
                FakeGoogle.sign(google.claims("sub-1", "ana@example.test").build(), FakeGoogle.newKey("fake-google"));

        assertSignInFailed(forged);
    }

    @Test
    void rejectsAnHs256Token() throws Exception {
        var jwt = new SignedJWT(
                new JWSHeader(JWSAlgorithm.HS256),
                google.claims("sub-1", "ana@example.test").build());
        jwt.sign(new MACSigner("a-shared-secret-of-at-least-32-bytes!!"));

        assertSignInFailed(jwt.serialize());
    }

    @Test
    void rejectsAnotherIssuer() {
        assertSignInFailed(token(c -> c.issuer("https://evil.example")));
    }

    @Test
    void rejectsAnotherAudience() {
        assertSignInFailed(token(c -> c.audience("someone-else.apps.googleusercontent.com")));
    }

    @Test
    void rejectsAnExpiredTokenByTheInjectedClock() {
        var token = google.idToken("sub-1", "ana@example.test");
        // One hour of validity plus the 60 s of clock skew allowed against Google.
        clock.advance(Duration.ofHours(1).plusSeconds(60));
        assertThat(tokens.verify(token).subject()).isEqualTo("sub-1");

        clock.advance(Duration.ofSeconds(1));
        assertSignInFailed(token);
    }

    @Test
    void rejectsATokenWithoutExpiry() {
        assertSignInFailed(token(c -> c.expirationTime(null)));
    }

    @Test
    void rejectsAnUnverifiedEmail() {
        assertSignInFailed(token(c -> c.claim("email_verified", false)));
        assertSignInFailed(token(c -> c.claim("email_verified", null)));
    }

    @Test
    void rejectsATokenWithoutEmail() {
        assertSignInFailed(token(c -> c.claim("email", null)));
    }

    @Test
    void rejectsGarbage() {
        assertSignInFailed("not-a-jwt");
    }

    @Test
    void withoutClientIdsItAnswersNotConfigured() {
        var unconfigured = new GoogleIdTokens(google.jwks(), " ", clock);

        assertThatThrownBy(() -> unconfigured.verify(google.idToken("sub-1", "ana@example.test")))
                .isInstanceOfSatisfying(
                        AuthException.class,
                        e -> assertThat(e.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE));
    }

    private GoogleIdTokens.GoogleUser verify(UnaryOperator<JWTClaimsSet.Builder> change) {
        return tokens.verify(token(change));
    }

    private String token(UnaryOperator<JWTClaimsSet.Builder> change) {
        return google.sign(
                change.apply(google.claims("sub-1", "ana@example.test")).build());
    }

    private void assertSignInFailed(String token) {
        assertThatThrownBy(() -> tokens.verify(token))
                .isInstanceOfSatisfying(
                        AuthException.class, e -> assertThat(e.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED));
    }
}
