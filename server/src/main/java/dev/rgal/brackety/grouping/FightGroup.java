package dev.rgal.brackety.grouping;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Instant;
import java.util.UUID;

@Entity
public class FightGroup {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID eventId;
    private UUID categoryId;
    private UUID matId;
    private int number;
    private UUID createdBy;
    private Instant createdAt;

    protected FightGroup() {}

    FightGroup(UUID eventId, UUID categoryId, UUID matId, int number, UUID createdBy, Instant now) {
        this.eventId = eventId;
        this.categoryId = categoryId;
        this.matId = matId;
        this.number = number;
        this.createdBy = createdBy;
        this.createdAt = now;
    }

    public UUID getId() {
        return id;
    }

    public UUID getEventId() {
        return eventId;
    }

    public UUID getCategoryId() {
        return categoryId;
    }

    public UUID getMatId() {
        return matId;
    }

    public int getNumber() {
        return number;
    }

    public UUID getCreatedBy() {
        return createdBy;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
