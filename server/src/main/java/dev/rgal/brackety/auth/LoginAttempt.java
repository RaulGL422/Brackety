package dev.rgal.brackety.auth;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import java.time.Duration;
import java.time.Instant;

@Entity
class LoginAttempt {

    static final int MAX_FAILURES = 5;
    static final Duration LOCK_DURATION = Duration.ofMinutes(15);

    @Id
    private String attemptKey;

    private int failures;
    private Instant lockedUntil;

    protected LoginAttempt() {}

    boolean isLocked(Instant now) {
        return lockedUntil != null && now.isBefore(lockedUntil);
    }

    void recordFailure(Instant now) {
        failures++;
        if (failures >= MAX_FAILURES) {
            failures = 0;
            lockedUntil = now.plus(LOCK_DURATION);
        }
    }

    void reset() {
        failures = 0;
        lockedUntil = null;
    }
}
