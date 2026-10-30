package dev.rgal.brackety.event;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.util.UUID;

@Entity
public class EventCategory {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID eventId;
    private String name;
    private int minAge;
    private int maxAge;

    protected EventCategory() {}

    public EventCategory(UUID eventId, String name, int minAge, int maxAge) {
        this.eventId = eventId;
        this.name = name;
        this.minAge = minAge;
        this.maxAge = maxAge;
    }

    public UUID getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public int getMinAge() {
        return minAge;
    }

    public int getMaxAge() {
        return maxAge;
    }

    public boolean contains(int age) {
        return age >= minAge && age <= maxAge;
    }
}
