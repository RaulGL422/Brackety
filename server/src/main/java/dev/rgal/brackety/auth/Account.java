package dev.rgal.brackety.auth;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
class Account {

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

    protected Account() {}

    Account(String email, String passwordHash, LocalDate birthDate, String locale, Instant now) {
        this.email = email;
        this.passwordHash = passwordHash;
        this.birthDate = birthDate;
        this.locale = locale;
        this.status = Status.ACTIVE;
        this.createdAt = now;
        this.updatedAt = now;
    }

    UUID getId() {
        return id;
    }

    String getEmail() {
        return email;
    }

    String getPasswordHash() {
        return passwordHash;
    }

    boolean isEmailVerified() {
        return emailVerified;
    }

    String getLocale() {
        return locale;
    }

    boolean isActive() {
        return status == Status.ACTIVE;
    }

    void markEmailVerified(Instant now) {
        emailVerified = true;
        updatedAt = now;
    }

    void changePassword(String passwordHash, Instant now) {
        this.passwordHash = passwordHash;
        updatedAt = now;
    }

    void markReminderSent(Instant now) {
        verificationReminderSentAt = now;
    }
}
