package dev.rgal.brackety.staff;

import dev.rgal.brackety.event.EventRole;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

/** A helper or referee invited by email (F1-5); the link sent is single use and only its hash is kept. */
@Entity
public class StaffInvitation {

    static final Duration LIFETIME = Duration.ofDays(14);

    @Id
    private UUID id;

    private UUID eventId;
    private String email;

    @Enumerated(EnumType.STRING)
    private EventRole role;

    private String tokenHash;
    private Instant sentAt;
    private Instant expiresAt;
    private Instant acceptedAt;
    private UUID acceptedBy;

    protected StaffInvitation() {}

    StaffInvitation(UUID eventId, String email, EventRole role, String tokenHash, Instant now) {
        this.id = UUID.randomUUID();
        this.eventId = eventId;
        this.email = email;
        this.role = role;
        resend(tokenHash, now);
    }

    /** A new link; the one sent before stops working. */
    void resend(String tokenHash, Instant now) {
        this.tokenHash = tokenHash;
        this.sentAt = now;
        this.expiresAt = now.plus(LIFETIME);
    }

    void accept(UUID accountId, Instant now) {
        this.acceptedAt = now;
        this.acceptedBy = accountId;
    }

    boolean isUsable(Instant now) {
        return acceptedAt == null && now.isBefore(expiresAt);
    }

    public UUID getId() {
        return id;
    }

    public UUID getEventId() {
        return eventId;
    }

    public String getEmail() {
        return email;
    }

    public EventRole getRole() {
        return role;
    }

    public Instant getSentAt() {
        return sentAt;
    }

    public Instant getExpiresAt() {
        return expiresAt;
    }
}
