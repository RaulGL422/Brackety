package dev.rgal.brackety.staff;

import dev.rgal.brackety.event.EventRole;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import java.time.Instant;
import java.util.UUID;

/**
 * A referee or helper let in by QR (docs/modulos/ayudantes-permisos.md): a temporary account for one event, signed
 * in with a single-use code. It ends with the phase or when the club ends it.
 */
@Entity
class TemporaryAccess {

    @Id
    private UUID id;

    private UUID eventId;
    private UUID accountId;
    private String name;

    @Enumerated(EnumType.STRING)
    private EventRole role;

    private String tokenHash;
    private UUID createdBy;
    private Instant createdAt;
    private Instant renewedAt;
    private Instant signedInAt;
    private Instant endedAt;

    protected TemporaryAccess() {}

    TemporaryAccess(
            UUID eventId, UUID accountId, String name, EventRole role, String tokenHash, UUID createdBy, Instant now) {
        this.id = UUID.randomUUID();
        this.eventId = eventId;
        this.accountId = accountId;
        this.name = name;
        this.role = role;
        this.createdBy = createdBy;
        this.createdAt = now;
        renew(tokenHash, now);
    }

    /** A new code: the previous one, used or not, stops working. */
    void renew(String tokenHash, Instant now) {
        this.tokenHash = tokenHash;
        this.renewedAt = now;
        this.signedInAt = null;
        this.endedAt = null;
    }

    /** The code is spent: whoever wants to sign in again needs a new one from the club. */
    void signedIn(Instant now) {
        this.tokenHash = null;
        this.signedInAt = now;
    }

    void end(Instant now) {
        this.tokenHash = null;
        this.endedAt = now;
    }

    UUID getId() {
        return id;
    }

    UUID getEventId() {
        return eventId;
    }

    UUID getAccountId() {
        return accountId;
    }

    String getName() {
        return name;
    }

    EventRole getRole() {
        return role;
    }

    Instant getRenewedAt() {
        return renewedAt;
    }

    Instant getSignedInAt() {
        return signedInAt;
    }

    boolean isEnded() {
        return endedAt != null;
    }

    boolean isWaiting() {
        return tokenHash != null;
    }
}
