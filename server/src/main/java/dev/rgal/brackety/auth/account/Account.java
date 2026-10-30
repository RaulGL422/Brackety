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
import java.util.Locale;
import java.util.UUID;

@Entity
public class Account {

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

    String getLocale() {
        return locale;
    }

    public boolean isActive() {
        return status == Status.ACTIVE;
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
