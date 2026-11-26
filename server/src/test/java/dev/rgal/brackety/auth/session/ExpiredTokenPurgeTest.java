package dev.rgal.brackety.auth.session;

import static org.assertj.core.api.Assertions.assertThat;

import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.common.crypto.Sha256;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

class ExpiredTokenPurgeTest extends AuthIntegrationTest {

    @Autowired
    AuthService auth;

    @Autowired
    ExpiredTokenPurge purge;

    @Test
    void oldTokensGoAndLiveOnesAndRecentTheftEvidenceStay() {
        auth.register(registration("ana@example.test"));
        var old = auth.login("ana@example.test", PASSWORD, "203.0.113.10");
        clock.advance(SessionService.REFRESH_TTL.plusDays(10));
        var recentlyExpired = auth.login("ana@example.test", PASSWORD, "203.0.113.10");
        clock.advance(SessionService.REFRESH_TTL
                .plus(ExpiredTokenPurge.THEFT_EVIDENCE)
                .minusDays(9));
        var live = auth.login("ana@example.test", PASSWORD, "203.0.113.10");

        purge.purge();

        assertThat(refreshTokens()).hasSize(2);
        assertThat(exists(old.refreshToken())).isFalse();
        assertThat(exists(recentlyExpired.refreshToken())).isTrue();
        assertThat(exists(live.refreshToken())).isTrue();
        assertThat(jdbc.sql("select count(*) from email_token")
                        .query(Integer.class)
                        .single())
                .isZero();
    }

    private List<String> refreshTokens() {
        return jdbc.sql("select token_hash from refresh_token")
                .query(String.class)
                .list();
    }

    private boolean exists(String raw) {
        return refreshTokens().contains(Sha256.hex(raw));
    }
}
