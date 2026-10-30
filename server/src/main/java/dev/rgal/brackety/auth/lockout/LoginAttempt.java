package dev.rgal.brackety.auth.lockout;

import dev.rgal.brackety.common.crypto.Sha256;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

@Entity
public class LoginAttempt {

    public static final int MAX_EMAIL_FAILURES = 5;
    // High on purpose: at an event many users share one public IP (NAT); this only stops mass attacks.
    public static final int MAX_IP_FAILURES = 30;
    static final Duration WINDOW = Duration.ofMinutes(15);
    public static final Duration LOCK_DURATION = Duration.ofMinutes(15);

    // No 0/O or 1/I/L: the user reads the id out to the superadmin.
    private static final String LOCK_ID_ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ";
    private static final SecureRandom RANDOM = new SecureRandom();

    @Id
    private String attemptKey;

    private int failures;
    private Instant lastFailureAt;
    private Instant lockedUntil;
    private String lockId;
    private String ip;
    private UUID accountId;

    protected LoginAttempt() {}

    public boolean isLocked(Instant now) {
        return lockedUntil != null && now.isBefore(lockedUntil);
    }

    public String getLockId() {
        return lockId;
    }

    public void setIp(String ip) {
        this.ip = ip;
    }

    public void setAccountId(UUID accountId) {
        this.accountId = accountId;
    }

    UUID getAccountId() {
        return accountId;
    }

    /** Returns true when this failure locks the key. */
    public boolean recordFailure(Instant now, int maxFailures) {
        if (lastFailureAt != null && now.isAfter(lastFailureAt.plus(WINDOW))) {
            failures = 0;
        }
        failures++;
        lastFailureAt = now;
        if (failures < maxFailures) {
            return false;
        }
        failures = 0;
        lockedUntil = now.plus(LOCK_DURATION);
        lockId = newLockId();
        return true;
    }

    public void reset() {
        failures = 0;
        lastFailureAt = null;
        lockedUntil = null;
        lockId = null;
    }

    // Keyed by email, not account, so unknown emails lock the same way and do not reveal which exist.
    public static String emailKey(String normalizedEmail) {
        return "email:" + Sha256.hex(normalizedEmail);
    }

    static String newLockId() {
        var id = new StringBuilder("L-");
        for (int i = 0; i < 6; i++) {
            id.append(LOCK_ID_ALPHABET.charAt(RANDOM.nextInt(LOCK_ID_ALPHABET.length())));
        }
        return id.toString();
    }
}
