package dev.rgal.brackety.auth.session;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.AuthTestConfig;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.email.EmailVerificationService;
import dev.rgal.brackety.auth.session.SessionService.Session;
import dev.rgal.brackety.common.crypto.Sha256;
import java.time.Duration;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.security.oauth2.jwt.JwtDecoder;

class SessionServiceTest extends AuthIntegrationTest {

    @Autowired
    AuthService auth;

    @Autowired
    SessionService sessions;

    @Autowired
    AccountRepository accounts;

    @Autowired
    JwtDecoder jwtDecoder;

    @Autowired
    EmailVerificationService verification;

    private Session first;

    @BeforeEach
    void logIn() {
        auth.register(registration("ana@example.test"));
        first = auth.login("ana@example.test", PASSWORD, "203.0.113.10");
    }

    @Test
    void accessTokenCarriesTheAccountAndProfilesForFifteenMinutes() {
        var jwt = jwtDecoder.decode(first.accessToken());

        var accountId = accounts.findByEmail("ana@example.test").orElseThrow().getId();
        assertThat(jwt.getSubject()).isEqualTo(accountId.toString());
        assertThat(jwt.getClaimAsStringList("profiles")).containsExactly("CLUB");
        assertThat(jwt.getExpiresAt()).isEqualTo(AuthTestConfig.START.plus(Duration.ofMinutes(15)));
    }

    @Test
    void anUnverifiedAccountGetsEmailVerifiedFalse() {
        assertThat(first.emailVerified()).isFalse();
        assertThat(jwtDecoder.decode(first.accessToken()).getClaimAsBoolean("email_verified"))
                .isFalse();
    }

    @Test
    void theRefreshAfterVerifyingCarriesEmailVerifiedTrue() {
        verification.verify(tokenIn(emails.sentTo("ana@example.test").getFirst()));

        var second = sessions.refresh(first.refreshToken());

        assertThat(second.emailVerified()).isTrue();
        assertThat(jwtDecoder.decode(second.accessToken()).getClaimAsBoolean("email_verified"))
                .isTrue();
    }

    @Test
    void refreshTokenIsStoredOnlyAsAHash() {
        var stored = jdbc.sql("select token_hash from refresh_token")
                .query(String.class)
                .single();

        assertThat(stored).isEqualTo(Sha256.hex(first.refreshToken())).isNotEqualTo(first.refreshToken());
    }

    @Test
    void refreshRotatesWithinTheSameFamily() {
        var second = sessions.refresh(first.refreshToken());

        assertThat(second.refreshToken()).isNotEqualTo(first.refreshToken());
        assertThat(second.accessToken()).isNotBlank();
        assertThat(jdbc.sql("select count(distinct family_id) from refresh_token")
                        .query(Integer.class)
                        .single())
                .isOne();
        assertThat(jdbc.sql("select count(*) from refresh_token where used_at is not null")
                        .query(Integer.class)
                        .single())
                .isOne();
    }

    @Test
    void reusingAUsedTokenRevokesTheWholeFamily() {
        var second = sessions.refresh(first.refreshToken());
        clock.advance(SessionService.REUSE_GRACE.plusSeconds(1));

        assertUnauthorized(() -> sessions.refresh(first.refreshToken()));

        assertUnauthorized(() -> sessions.refresh(second.refreshToken()));
        assertThat(count("refresh_token where revoked_at is null")).isZero();
    }

    @Test
    void aRepeatWithinTheGraceGetsTheSamePairWithoutRevokingTheSession() {
        var second = sessions.refresh(first.refreshToken());
        clock.advance(SessionService.REUSE_GRACE);

        var repeat = sessions.refresh(first.refreshToken());

        assertThat(repeat.accessToken()).isEqualTo(second.accessToken());
        assertThat(repeat.refreshToken()).isEqualTo(second.refreshToken());
        assertThat(repeat.expiresIn()).isEqualTo(second.expiresIn() - SessionService.REUSE_GRACE.toSeconds());
        assertThat(sessions.refresh(first.refreshToken()).refreshToken()).isEqualTo(second.refreshToken());
        assertThat(count("refresh_token")).isEqualTo(2);
        assertThat(count("refresh_token where revoked_at is not null")).isZero();
        assertThat(emails.sentTo("ana@example.test")).hasSize(1);
        assertThat(sessions.refresh(second.refreshToken()).accessToken()).isNotBlank();
    }

    @Test
    void aRepeatAfterTheNewPairWasRotatedIsRejectedWithoutRevokingTheSession() {
        var second = sessions.refresh(first.refreshToken());
        var third = sessions.refresh(second.refreshToken());
        clock.advance(Duration.ofSeconds(5));

        assertUnauthorized(() -> sessions.refresh(first.refreshToken()));

        assertThat(count("refresh_token where revoked_at is not null")).isZero();
        assertThat(sessions.refresh(third.refreshToken()).accessToken()).isNotBlank();
    }

    @Test
    void aRepeatAfterLogoutIsRejected() {
        var second = sessions.refresh(first.refreshToken());
        sessions.logout(second.refreshToken());

        assertUnauthorized(() -> sessions.refresh(first.refreshToken()));
    }

    @Test
    void aRepeatAfterTheGraceRevokesTheFamilyAsAnyReuse() {
        sessions.refresh(first.refreshToken());
        sessions.refresh(first.refreshToken());
        clock.advance(SessionService.REUSE_GRACE.plusSeconds(1));

        assertUnauthorized(() -> sessions.refresh(first.refreshToken()));

        assertThat(count("refresh_token where revoked_at is null")).isZero();
    }

    @Test
    void reuseDoesNotTouchOtherSessions() {
        var other = auth.login("ana@example.test", PASSWORD, "203.0.113.10");
        sessions.refresh(first.refreshToken());
        clock.advance(SessionService.REUSE_GRACE.plusSeconds(1));

        assertUnauthorized(() -> sessions.refresh(first.refreshToken()));

        assertThat(sessions.refresh(other.refreshToken()).accessToken()).isNotBlank();
    }

    @Test
    void refreshExpiresAfterThirtyDaysAndEachRotationStartsThirtyNewDays() {
        clock.advance(Duration.ofDays(29));
        var second = sessions.refresh(first.refreshToken());

        clock.advance(Duration.ofDays(29));
        var third = sessions.refresh(second.refreshToken());

        clock.advance(Duration.ofDays(30));
        assertUnauthorized(() -> sessions.refresh(third.refreshToken()));
    }

    @Test
    void unknownOrMissingTokenIsRejected() {
        assertUnauthorized(() -> sessions.refresh("not-a-token"));
        assertUnauthorized(() -> sessions.refresh(null));
    }

    @Test
    void logoutRevokesTheFamily() {
        var second = sessions.refresh(first.refreshToken());

        sessions.logout(second.refreshToken());

        assertUnauthorized(() -> sessions.refresh(second.refreshToken()));
        assertThat(count("refresh_token where revoked_at is null")).isZero();
    }

    @Test
    void logoutWithoutAValidTokenDoesNothing() {
        sessions.logout(null);
        sessions.logout("not-a-token");

        assertThat(sessions.refresh(first.refreshToken()).accessToken()).isNotBlank();
    }

    private static void assertUnauthorized(Runnable call) {
        assertThatThrownBy(call::run)
                .isInstanceOfSatisfying(
                        AuthException.class, e -> assertThat(e.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED));
    }
}
