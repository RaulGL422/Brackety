package dev.rgal.brackety.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import com.jayway.jsonpath.JsonPath;
import com.nimbusds.jose.jwk.source.ImmutableSecret;
import dev.rgal.brackety.auth.session.ShortLivedTokens;
import dev.rgal.brackety.event.EventApiTest;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.List;
import java.util.UUID;
import javax.crypto.spec.SecretKeySpec;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * Server battery, «Ataques» (docs/04-testing.md, GR-8): access tokens someone made or changed by hand, and a QR
 * account trying to reach beyond its own event. Every forged token is a 401 on a page only the club may open, while
 * the genuine one opens it, so a refusal is never just a wrong path. IDOR and broken input are in
 * {@code PermissionMatrixTest}; refresh token reuse in {@code SessionServiceTest}; rate limits in their own tests.
 */
class AccessTokenAttacksTest extends EventApiTest {

    private static final Base64.Encoder BASE64 = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder UNBASE64 = Base64.getUrlDecoder();

    @Autowired
    ShortLivedTokens shortLived;

    @Value("${brackety.auth.jwt-secret}")
    String secret;

    @Test
    void theGenuineTokenOpensTheClubsSettings() throws Exception {
        assertThat(settingsWith(token("club1"))).isEqualTo(200);
    }

    @Test
    void noTokenOrOneThatIsNotAJwtIsRefused() throws Exception {
        assertThat(status(get(settings()))).isEqualTo(401);
        for (var junk : List.of("", "abc", "a.b.c", "Bearer", refreshToken("club1"))) {
            assertThat(settingsWith(junk)).as("bearer «%s»", junk).isEqualTo(401);
        }
    }

    // The classic forgery: the header says there is no signature, and the payload is a real club's.
    @Test
    void anUnsignedTokenIsRefused() throws Exception {
        var genuine = token("club1").split("\\.");
        var unsigned = encode("{\"alg\":\"none\",\"typ\":\"JWT\"}") + "." + genuine[1] + ".";

        assertThat(settingsWith(unsigned)).isEqualTo(401);
    }

    @Test
    void aTokenSignedWithAnotherKeyIsRefused() throws Exception {
        var otherKey = "another-secret-of-the-same-length-as-the-real-one-1234".getBytes(StandardCharsets.UTF_8);

        assertThat(settingsWith(signed(otherKey, MacAlgorithm.HS256, "club1"))).isEqualTo(401);
    }

    // With the right key but another algorithm than the server's: still refused, the algorithm is pinned.
    @Test
    void aTokenWithAnotherAlgorithmIsRefused() throws Exception {
        var key = secret.getBytes(StandardCharsets.UTF_8);

        assertThat(settingsWith(signed(key, MacAlgorithm.HS384, "club1"))).isEqualTo(401);
    }

    // A referee swaps their own token's subject for the club's and keeps the signature.
    @Test
    void aTokenWithAnotherSubjectIsRefused() throws Exception {
        var parts = token("arbitro1").split("\\.");
        var payload = new String(UNBASE64.decode(parts[1]), StandardCharsets.UTF_8)
                .replace(accountId("arbitro1").toString(), accountId("club1").toString());

        assertThat(settingsWith(parts[0] + "." + encode(payload) + "." + parts[2]))
                .isEqualTo(401);
    }

    // No clock skew: one second before it ends it works, one second after it does not. At its very second it still
    // works: Spring's validator refuses only after exp (RFC 7519 says before); one second, no practical risk.
    @Test
    void anExpiredTokenIsRefused() throws Exception {
        var token = token("club1");
        var expiresAt = Instant.ofEpochSecond(((Number) JsonPath.read(
                        new String(UNBASE64.decode(token.split("\\.")[1]), StandardCharsets.UTF_8), "$.exp"))
                .longValue());

        clock.set(expiresAt.minusSeconds(1));
        assertThat(settingsWith(token)).isEqualTo(200);
        clock.set(expiresAt.plusSeconds(1));
        assertThat(settingsWith(token)).isEqualTo(401);
    }

    // Signed with the same key, but for proving the password again or restoring a deleted account: not an access.
    @Test
    void aTokenForAnotherPurposeIsRefused() throws Exception {
        for (var purpose : ShortLivedTokens.Purpose.values()) {
            assertThat(settingsWith(shortLived.issue(accountId("club1"), purpose)))
                    .as(purpose.name())
                    .isEqualTo(401);
        }
    }

    // A QR referee reaches nothing of another club's event. A phase its club creates meanwhile takes it along on
    // purpose (GR-2: the access goes on to the next phase with its mat), so it sees exactly those two.
    @Test
    void aQrAccountStaysInsideItsOwnEvent() throws Exception {
        var qr = qrReferee();
        var rival = rivalEvent();
        var nextPhase = nextPhase();

        List<String> visible = JsonPath.read(body(get("/api/v1/events"), qr), "$[*].id");
        assertThat(visible).containsExactlyInAnyOrder(eventId.toString(), nextPhase.toString());
        for (var path : List.of("/phase", "/rulebook/info", "/mats", "/settings")) {
            assertThat(status(get("/api/v1/events/" + rival + path), qr))
                    .as(path)
                    .isIn(403, 404);
        }
        for (var mat : mats(rival)) {
            assertThat(status(get("/api/v1/mats/" + mat + "/board"), qr)).isIn(403, 404);
        }
        assertThat(status(post("/api/v1/events").content("""
                                        {"name":"Mío","date":"2027-05-08","discipline":"TAMBO","mats":1}"""), qr)).isIn(401, 403);
    }

    private String qrReferee() throws Exception {
        var created = body(
                post("/api/v1/events/" + eventId + "/temporary-access")
                        .content("{\"name\":\"Juan\",\"role\":\"REFEREE\",\"mat\":3}"),
                token("club1"));
        String link = JsonPath.read(created, "$.link");
        var signedIn = mvc.perform(post("/api/v1/auth/temporary")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"%s\"}".formatted(link.substring(link.indexOf("code=") + 5))))
                .andReturn()
                .getResponse()
                .getContentAsString();
        return JsonPath.read(signedIn, "$.accessToken");
    }

    private UUID rivalEvent() throws Exception {
        var rival = "rival@example.test";
        auth.register(registration(rival));
        jdbc.sql("update account set email_verified = true where email = ?")
                .param(rival)
                .update();
        var created = body(
                post("/api/v1/events").content("""
                        {"name":"Rival","date":"2027-05-08","discipline":"TAMBO","mats":2}"""),
                auth.login(rival, PASSWORD, "127.0.0.1").accessToken());
        var id = UUID.fromString(JsonPath.read(created, "$.eventId"));
        startPhase(id);
        return id;
    }

    private UUID nextPhase() throws Exception {
        var created = body(post("/api/v1/events/" + eventId + "/league/phases").content("""
                        {"name":"Fase 2","date":"2027-04-10","discipline":"TAMBO","attendancePoints":0}"""), token("club1"));
        var id = UUID.fromString(JsonPath.read(created, "$.eventId"));
        startPhase(id);
        return id;
    }

    private List<UUID> mats(UUID event) {
        return jdbc.sql("select id from mat where event_id = ?")
                .param(event)
                .query(UUID.class)
                .list();
    }

    private String signed(byte[] key, MacAlgorithm algorithm, String username) {
        var encoder = new NimbusJwtEncoder(new ImmutableSecret<>(new SecretKeySpec(key, algorithm.getName())));
        var now = clock.instant();
        var claims = JwtClaimsSet.builder()
                .subject(accountId(username).toString())
                .issuedAt(now)
                .expiresAt(now.plusSeconds(600))
                .claim("profiles", List.of("CLUB"))
                .claim("email_verified", true)
                .claim("purpose", "ACCESS")
                .build();
        return encoder.encode(
                        JwtEncoderParameters.from(JwsHeader.with(algorithm).build(), claims))
                .getTokenValue();
    }

    private String token(String username) {
        return auth.login(username, username, "127.0.0.1").accessToken();
    }

    private String refreshToken(String username) {
        return auth.login(username, username, "127.0.0.1").refreshToken();
    }

    private String settings() {
        return "/api/v1/events/" + eventId + "/settings";
    }

    private int settingsWith(String token) throws Exception {
        return status(get(settings()), token);
    }

    private int status(MockHttpServletRequestBuilder request) throws Exception {
        return mvc.perform(request.contentType(MediaType.APPLICATION_JSON))
                .andReturn()
                .getResponse()
                .getStatus();
    }

    private int status(MockHttpServletRequestBuilder request, String token) throws Exception {
        return status(request.header(HttpHeaders.AUTHORIZATION, "Bearer " + token));
    }

    private String body(MockHttpServletRequestBuilder request, String token) throws Exception {
        var response = mvc.perform(request.header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON))
                .andReturn()
                .getResponse();
        assertThat(response.getStatus()).as(response.getContentAsString()).isBetween(200, 299);
        return response.getContentAsString();
    }

    private static String encode(String json) {
        return BASE64.encodeToString(json.getBytes(StandardCharsets.UTF_8));
    }
}
