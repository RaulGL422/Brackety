package dev.rgal.brackety.auth.admin;

import static org.assertj.core.api.Assertions.assertThat;

import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.RemoteKeySourceException;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.proc.SecurityContext;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.PlainJWT;
import com.nimbusds.jwt.SignedJWT;
import dev.rgal.brackety.auth.admin.CloudflareAccess.Outcome;
import dev.rgal.brackety.common.MutableClock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.util.Date;
import java.util.function.UnaryOperator;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class CloudflareAccessTest {

    private final MutableClock clock = new MutableClock(Instant.parse("2027-03-10T09:00:00Z"), ZoneId.of("UTC"));
    private final FakeCloudflareAccess cloudflare = new FakeCloudflareAccess(clock);
    private final CloudflareAccess access = cloudflare.access();

    @Test
    void acceptsTheAssertionOfTheTeamAndApplication() {
        assertThat(access.check(cloudflare.assertion())).isEqualTo(Outcome.ALLOWED);
    }

    @ParameterizedTest
    @ValueSource(
            strings = {
                FakeCloudflareAccess.TEAM_DOMAIN,
                "https://" + FakeCloudflareAccess.TEAM_DOMAIN,
                " https://" + FakeCloudflareAccess.TEAM_DOMAIN + "/ "
            })
    void takesTheTeamDomainWithOrWithoutScheme(String teamDomain) {
        var configured = CloudflareAccess.of(cloudflare.jwks(), teamDomain, FakeCloudflareAccess.AUDIENCE, clock);

        assertThat(configured.check(cloudflare.assertion())).isEqualTo(Outcome.ALLOWED);
        assertThat(CloudflareAccess.certsUrl(teamDomain))
                .isEqualTo("https://brackety-test.cloudflareaccess.com/cdn-cgi/access/certs");
    }

    @Test
    void acceptsAnAudienceListThatContainsOurs() {
        assertThat(access.check(token(c -> c.audience(java.util.List.of("other-app", FakeCloudflareAccess.AUDIENCE)))))
                .isEqualTo(Outcome.ALLOWED);
    }

    @Test
    void deniesAMissingAssertion() {
        assertThat(access.check(null)).isEqualTo(Outcome.DENIED);
        assertThat(access.check(" ")).isEqualTo(Outcome.DENIED);
    }

    @Test
    void deniesAnAssertionSignedWithAnotherKey() {
        var forged =
                FakeCloudflareAccess.sign(cloudflare.claims().build(), FakeCloudflareAccess.newKey("fake-cloudflare"));

        assertThat(access.check(forged)).isEqualTo(Outcome.DENIED);
    }

    @Test
    void deniesAnHs256Assertion() throws Exception {
        var jwt = new SignedJWT(
                new JWSHeader(JWSAlgorithm.HS256), cloudflare.claims().build());
        jwt.sign(new MACSigner("a-shared-secret-of-at-least-32-bytes!!"));

        assertThat(access.check(jwt.serialize())).isEqualTo(Outcome.DENIED);
    }

    @Test
    void deniesAnotherIssuer() {
        assertThat(access.check(token(c -> c.issuer("https://other-team.cloudflareaccess.com"))))
                .isEqualTo(Outcome.DENIED);
    }

    @Test
    void deniesAnotherAudience() {
        assertThat(access.check(token(c -> c.audience("another-application")))).isEqualTo(Outcome.DENIED);
        assertThat(access.check(token(c -> c.audience((String) null)))).isEqualTo(Outcome.DENIED);
    }

    @Test
    void deniesAnExpiredAssertionByTheInjectedClock() {
        var assertion = token(c -> c.expirationTime(Date.from(clock.instant().plus(Duration.ofMinutes(5)))));
        // Five minutes plus the 60 s of skew allowed against Cloudflare.
        clock.advance(Duration.ofMinutes(6));
        assertThat(access.check(assertion)).isEqualTo(Outcome.ALLOWED);

        clock.advance(Duration.ofSeconds(1));
        assertThat(access.check(assertion)).isEqualTo(Outcome.DENIED);
    }

    @Test
    void deniesAnAssertionWithoutExpiry() {
        assertThat(access.check(token(c -> c.expirationTime(null)))).isEqualTo(Outcome.DENIED);
    }

    @Test
    void deniesGarbage() {
        assertThat(access.check("not-a-jwt")).isEqualTo(Outcome.DENIED);
    }

    @Test
    void unreachableKeysAreUnavailableNotDenied() {
        JWKSource<SecurityContext> down = (selector, context) -> {
            throw new RemoteKeySourceException("Cloudflare is down", null);
        };
        var unreachable =
                CloudflareAccess.of(down, FakeCloudflareAccess.TEAM_DOMAIN, FakeCloudflareAccess.AUDIENCE, clock);

        assertThat(unreachable.check(cloudflare.assertion())).isEqualTo(Outcome.UNAVAILABLE);
    }

    @Test
    void withoutTeamDomainOrAudienceEverythingIsUnavailable() {
        var noTeam = CloudflareAccess.of(null, " ", FakeCloudflareAccess.AUDIENCE, clock);
        var noAudience = CloudflareAccess.of(cloudflare.jwks(), FakeCloudflareAccess.TEAM_DOMAIN, "", clock);

        assertThat(noTeam.check(cloudflare.assertion())).isEqualTo(Outcome.UNAVAILABLE);
        assertThat(noAudience.check(cloudflare.assertion())).isEqualTo(Outcome.UNAVAILABLE);
    }

    @Test
    void deniesAnUnsignedAssertion() {
        assertThat(access.check(new PlainJWT(cloudflare.claims().build()).serialize()))
                .isEqualTo(Outcome.DENIED);
    }

    @Test
    void theFilterAnswers403And503AsProblems() throws Exception {
        var denied = filter(access, null);
        var unavailable = filter(CloudflareAccess.of(null, "", "", clock), cloudflare.assertion());

        assertThat(denied.getStatus()).isEqualTo(403);
        assertThat(denied.getContentType()).isEqualTo("application/problem+json");
        assertThat(unavailable.getStatus()).isEqualTo(503);
        assertThat(unavailable.getContentType()).isEqualTo("application/problem+json");
        assertThat(filter(access, cloudflare.assertion()).getStatus()).isEqualTo(200);
    }

    private MockHttpServletResponse filter(CloudflareAccess access, String assertion) throws Exception {
        var request = new MockHttpServletRequest("GET", "/api/v1/admin/auth/locks");
        if (assertion != null) {
            request.addHeader(CloudflareAccess.HEADER, assertion);
        }
        var response = new MockHttpServletResponse();
        new CloudflareAccessFilter(access).doFilter(request, response, new MockFilterChain());
        return response;
    }

    private String token(UnaryOperator<JWTClaimsSet.Builder> change) {
        return cloudflare.sign(change.apply(cloudflare.claims()).build());
    }
}
