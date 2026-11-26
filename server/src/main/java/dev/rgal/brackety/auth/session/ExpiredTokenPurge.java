package dev.rgal.brackety.auth.session;

import dev.rgal.brackety.auth.email.EmailTokens;
import java.time.Clock;
import java.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

// Every refresh adds a row (every 15 minutes per signed-in device): without this the table only grows. A used token
// shown again is a theft even after it expired (SessionService revokes the family and warns the owner), so refresh
// rows stay a while after expiring. An expired email link is refused anyway.
@Component
class ExpiredTokenPurge {

    static final Duration THEFT_EVIDENCE = Duration.ofDays(30);

    private static final Logger log = LoggerFactory.getLogger(ExpiredTokenPurge.class);

    private final RefreshTokenRepository refreshTokens;
    private final EmailTokens emailTokens;
    private final Clock clock;

    ExpiredTokenPurge(RefreshTokenRepository refreshTokens, EmailTokens emailTokens, Clock clock) {
        this.refreshTokens = refreshTokens;
        this.emailTokens = emailTokens;
        this.clock = clock;
    }

    @Scheduled(initialDelayString = "PT30M", fixedDelayString = "P1D")
    @Transactional
    public void purge() {
        var now = clock.instant();
        var refresh = refreshTokens.deleteExpired(now.minus(THEFT_EVIDENCE));
        var email = emailTokens.deleteExpired(now);
        log.info("Expired tokens purged: {} refresh, {} email", refresh, email);
    }
}
