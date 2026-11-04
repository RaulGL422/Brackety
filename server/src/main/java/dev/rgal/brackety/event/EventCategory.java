package dev.rgal.brackety.event;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.util.UUID;

/** {@code teamSize} is null in an individual category; {@code groupSize} counts participants or teams. */
@Entity
public class EventCategory {

    public enum Format {
        INDIVIDUAL,
        TEAM
    }

    public static final int GROUP_SIZE = 4;

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID eventId;
    private String name;
    private int minAge;
    private int maxAge;

    @Enumerated(EnumType.STRING)
    private Format format;

    private Integer teamSize;
    private int groupSize;

    protected EventCategory() {}

    public EventCategory(UUID eventId, String name, int minAge, int maxAge) {
        this(eventId, name, minAge, maxAge, null);
    }

    /** A team category when {@code teamSize} is not null. */
    public EventCategory(UUID eventId, String name, int minAge, int maxAge, Integer teamSize) {
        this.eventId = eventId;
        update(name, minAge, maxAge, teamSize);
    }

    public void update(String name, int minAge, int maxAge, Integer teamSize) {
        this.name = name;
        this.minAge = minAge;
        this.maxAge = maxAge;
        this.format = teamSize == null ? Format.INDIVIDUAL : Format.TEAM;
        this.teamSize = teamSize;
        this.groupSize = GROUP_SIZE;
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

    public int getMinAge() {
        return minAge;
    }

    public int getMaxAge() {
        return maxAge;
    }

    public Format getFormat() {
        return format;
    }

    public boolean isTeam() {
        return format == Format.TEAM;
    }

    public Integer getTeamSize() {
        return teamSize;
    }

    public int getGroupSize() {
        return groupSize;
    }

    public boolean contains(int age) {
        return age >= minAge && age <= maxAge;
    }
}
