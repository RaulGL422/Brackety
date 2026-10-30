package dev.rgal.brackety.auth.account;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.Locale;
import java.util.UUID;

@Entity
public class Account {

    /** A deleted account can still be restored for this long; then it is purged for good. */
    public static final Duration DELETION_GRACE = Duration.ofDays(30);

    enum Status {
        ACTIVE,
        DELETED
    }

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private String email;
    private String passwordHash;
    private boolean emailVerified;
    private LocalDate birthDate;
    private String locale;

    @Enumerated(EnumType.STRING)
    private Status status;

    private Instant createdAt;
    private Instant updatedAt;
    private Instant verificationReminderSentAt;
    private Instant alreadyRegisteredSentAt;
    private Instant deletedAt;
    private Instant sessionsRevokedAt;

    protected Account() {}

    public Account(String email, String passwordHash, LocalDate birthDate, String locale, Instant now) {
        this.email = email;
        this.passwordHash = passwordHash;
        this.birthDate = birthDate;
        this.locale = locale;
        this.status = Status.ACTIVE;
        this.createdAt = now;
        this.updatedAt = now;
    }

    public UUID getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public boolean hasPassword() {
        return passwordHash != null;
    }

    public boolean isEmailVerified() {
        return emailVerified;
    }

    public LocalDate getBirthDate() {
        return birthDate;
    }

    public String getLocale() {
        return locale;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public boolean isActive() {
        return status == Status.ACTIVE;
    }

    /** The day the account will be purged, or null if it is not deleted. */
    public LocalDate deletesOn(ZoneId zone) {
        return deletedAt == null ? null : LocalDate.ofInstant(deletedAt.plus(DELETION_GRACE), zone);
    }

    /** Until the purge removes it, a deleted account can be restored only within the grace. */
    public boolean isRestorable(Instant now) {
        return !isActive() && now.isBefore(deletedAt.plus(DELETION_GRACE));
    }

    /** Access and reauth tokens issued before this call stop working, as they cannot be revoked one by one. */
    public void revokeSessions(Instant now) {
        sessionsRevokedAt = now;
        updatedAt = now;
    }

    // JWT times are whole seconds: a token issued in the same second as the revocation is a new one and is kept.
    public boolean acceptsTokenIssuedAt(Instant issuedAt) {
        return isActive()
                && issuedAt != null
                && (sessionsRevokedAt == null || !issuedAt.isBefore(sessionsRevokedAt.truncatedTo(ChronoUnit.SECONDS)));
    }

    public void markDeleted(Instant now) {
        status = Status.DELETED;
        deletedAt = now;
        updatedAt = now;
    }

    public void restore(Instant now) {
        status = Status.ACTIVE;
        deletedAt = null;
        updatedAt = now;
    }

    /** Only once the new address has been proved by its link, so it is verified too. */
    public void changeEmail(String newEmail, Instant now) {
        email = newEmail;
        emailVerified = true;
        updatedAt = now;
    }

    public void changeLocale(String locale, Instant now) {
        this.locale = locale;
        updatedAt = now;
    }

    public void markEmailVerified(Instant now) {
        emailVerified = true;
        updatedAt = now;
    }

    public void changePassword(String passwordHash, Instant now) {
        this.passwordHash = passwordHash;
        updatedAt = now;
    }

    public void removePassword(Instant now) {
        passwordHash = null;
        updatedAt = now;
    }

    /** Records the notice and returns true, unless one went out less than {@code interval} ago. */
    public boolean tryMarkAlreadyRegisteredSent(Instant now, Duration interval) {
        if (alreadyRegisteredSentAt != null && now.isBefore(alreadyRegisteredSentAt.plus(interval))) {
            return false;
        }
        alreadyRegisteredSentAt = now;
        return true;
    }

    public void markReminderSent(Instant now) {
        verificationReminderSentAt = now;
    }

    public static String normalizeEmail(String email) {
        return email.strip().toLowerCase(Locale.ROOT);
    }
}
