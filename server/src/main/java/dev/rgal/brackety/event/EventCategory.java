package dev.rgal.brackety.event;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.util.UUID;

/**
 * {@code teamSize} is null in an individual category. A group has {@code minGroupSize} to {@code maxGroupSize}
 * participants or teams; with {@code returnLeg} everyone fights everyone twice.
 */
@Entity
public class EventCategory {

    public enum Format {
        INDIVIDUAL,
        TEAM
    }

    /** A new category's groups: of 4, one leg, as before sizes could be chosen. */
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
    private int minGroupSize = GROUP_SIZE;
    private int maxGroupSize = GROUP_SIZE;
    private boolean returnLeg;

    /** Its own match length; null follows its modality. */
    private Integer matchSeconds;

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
    }

    public void setGroups(int minSize, int maxSize, boolean returnLeg) {
        this.minGroupSize = minSize;
        this.maxGroupSize = maxSize;
        this.returnLeg = returnLeg;
    }

    /** The same category in another phase of the league. */
    public EventCategory copyFor(UUID otherEventId) {
        var copy = new EventCategory(otherEventId, name, minAge, maxAge, teamSize);
        copy.matchSeconds = matchSeconds;
        copy.setGroups(minGroupSize, maxGroupSize, returnLeg);
        return copy;
    }

    public void setMatchSeconds(Integer matchSeconds) {
        this.matchSeconds = matchSeconds;
    }

    public Integer getMatchSeconds() {
        return matchSeconds;
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

    public int getMinGroupSize() {
        return minGroupSize;
    }

    public int getMaxGroupSize() {
        return maxGroupSize;
    }

    public boolean isReturnLeg() {
        return returnLeg;
    }

    public boolean contains(int age) {
        return age >= minAge && age <= maxAge;
    }
}
