package dev.rgal.brackety.grouping;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Instant;
import java.util.UUID;

/**
 * "Equipo N" in a team category; the number is unique in the event so the referee can call it.
 * A ghost team fills a group of 3 teams: it fights but scores nothing.
 */
@Entity
public class Team {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID eventId;
    private UUID categoryId;
    private int number;
    private boolean ghost;
    private UUID createdBy;
    private Instant createdAt;

    protected Team() {}

    Team(UUID eventId, UUID categoryId, int number, boolean ghost, UUID createdBy, Instant now) {
        this.eventId = eventId;
        this.categoryId = categoryId;
        this.number = number;
        this.ghost = ghost;
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

    public int getNumber() {
        return number;
    }

    public boolean isGhost() {
        return ghost;
    }
}
