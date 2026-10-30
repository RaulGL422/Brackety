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

    /** Liga Yoseikan tambo rules: 2 min per match, 15 points ends it, 10 points for attending. */
    public static Event tambo(UUID ownerAccountId, String name, LocalDate eventDate, Instant now) {
        var event = new Event();
        event.ownerAccountId = ownerAccountId;
        event.name = name;
        event.eventDate = eventDate;
        event.maxGroupsPerMat = 1;
        event.matchSeconds = 120;
        event.pointsLimit = 15;
        event.changeoverSeconds = 30;
        event.attendancePoints = 10;
        event.createdAt = now;
        return event;
    }

    public UUID getId() {
        return id;
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
