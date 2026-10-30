package dev.rgal.brackety.event;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.util.UUID;

@Entity
public class EventStaff {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID eventId;
    private UUID accountId;

    @Enumerated(EnumType.STRING)
    private EventRole role;

    protected EventStaff() {}

    public EventStaff(UUID eventId, UUID accountId, EventRole role) {
        this.eventId = eventId;
        this.accountId = accountId;
        this.role = role;
    }

    public UUID getEventId() {
        return eventId;
    }

    public UUID getAccountId() {
        return accountId;
    }

    public EventRole getRole() {
        return role;
    }
}
