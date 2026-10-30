package dev.rgal.brackety.auth;

import java.time.Clock;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

// Rows hold IPs in clear: keep them only while they still count for a window or a lock.
@Component
class LoginAttemptPurge {

    private final LoginAttemptRepository loginAttempts;
    private final Clock clock;

    LoginAttemptPurge(LoginAttemptRepository loginAttempts, Clock clock) {
        this.loginAttempts = loginAttempts;
        this.clock = clock;
    }

    @Scheduled(initialDelayString = "PT15M", fixedDelayString = "PT15M")
    @Transactional
    public void purge() {
        var now = clock.instant();
        loginAttempts.deleteFinished(now.minus(LoginAttempt.WINDOW), now);
    }
}
