package dev.rgal.brackety.event;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.util.UUID;

/** A club taking part in the event; {@code shortName} is optional (e.g. for narrow tables). */
@Entity
public class EventOrganization {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID eventId;
    private String name;
    private String shortName;

    protected EventOrganization() {}

    public EventOrganization(UUID eventId, String name, String shortName) {
        this.eventId = eventId;
        update(name, shortName);
    }

    public UUID getId() {
        return id;
    }

    public UUID getEventId() {
        return eventId;
    }

    public String getName() {
        return name;
    }

    public String getShortName() {
        return shortName;
    }

    void update(String name, String shortName) {
        this.name = name;
        this.shortName = shortName;
    }
}
