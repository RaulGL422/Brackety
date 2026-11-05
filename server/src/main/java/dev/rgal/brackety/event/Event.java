package dev.rgal.brackety.event;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Instant;
import java.time.LocalDate;
import java.time.Period;
import java.util.UUID;

@Entity
public class Event {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID ownerAccountId;
    private String name;
    private LocalDate eventDate;
    private int maxGroupsPerMat;
    private int matchSeconds;
    private int pointsLimit;
    private int changeoverSeconds;
    private int attendancePoints;
    private Instant createdAt;

    protected Event() {}

    public Event(
            UUID ownerAccountId,
            String name,
            LocalDate eventDate,
            int maxGroupsPerMat,
            int matchSeconds,
            int pointsLimit,
            int changeoverSeconds,
            int attendancePoints,
            Instant now) {
        this.ownerAccountId = ownerAccountId;
        this.name = name;
        this.eventDate = eventDate;
        this.maxGroupsPerMat = maxGroupsPerMat;
        this.matchSeconds = matchSeconds;
        this.pointsLimit = pointsLimit;
        this.changeoverSeconds = changeoverSeconds;
        this.attendancePoints = attendancePoints;
        this.createdAt = now;
    }

    /** Liga Yoseikan tambo rules: 2 min per match, 15 points ends it, 10 points for attending. */
    public static Event tambo(UUID ownerAccountId, String name, LocalDate eventDate, Instant now) {
        return new Event(ownerAccountId, name, eventDate, 1, 120, 15, 30, 10, now);
    }

    public UUID getId() {
        return id;
    }

    public UUID getOwnerAccountId() {
        return ownerAccountId;
    }

    public String getName() {
        return name;
    }

    public LocalDate getEventDate() {
        return eventDate;
    }

    public int getMaxGroupsPerMat() {
        return maxGroupsPerMat;
    }

    public int getMatchSeconds() {
        return matchSeconds;
    }

    public int getPointsLimit() {
        return pointsLimit;
    }

    public int getChangeoverSeconds() {
        return changeoverSeconds;
    }

    public int getAttendancePoints() {
        return attendancePoints;
    }

    public int ageOf(LocalDate birthDate) {
        return Period.between(birthDate, eventDate).getYears();
    }

    void update(String name, LocalDate eventDate, int maxGroupsPerMat) {
        this.name = name;
        this.eventDate = eventDate;
        this.maxGroupsPerMat = maxGroupsPerMat;
    }
}
