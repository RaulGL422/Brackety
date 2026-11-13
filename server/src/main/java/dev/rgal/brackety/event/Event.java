package dev.rgal.brackety.event;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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
    private UUID leagueId;
    private int phaseNumber;

    @Enumerated(EnumType.STRING)
    private Discipline discipline;

    private String name;
    private LocalDate eventDate;
    private int maxGroupsPerMat;
    private int matchSeconds;
    private int pointsLimit;
    private int teamMatchSeconds;
    private int teamPointsLimit;
    private int changeoverSeconds;
    private int minRestSeconds;
    private int attendancePoints;
    private Instant createdAt;
    private UUID originEventId;
    private String resultsImportHash;

    protected Event() {}

    public Event(
            UUID ownerAccountId,
            UUID leagueId,
            int phaseNumber,
            Discipline discipline,
            String name,
            LocalDate eventDate,
            int maxGroupsPerMat,
            int matchSeconds,
            int pointsLimit,
            int changeoverSeconds,
            int attendancePoints,
            Instant now) {
        this.ownerAccountId = ownerAccountId;
        this.leagueId = leagueId;
        this.phaseNumber = phaseNumber;
        this.discipline = discipline;
        this.name = name;
        this.eventDate = eventDate;
        this.maxGroupsPerMat = maxGroupsPerMat;
        this.matchSeconds = matchSeconds;
        this.pointsLimit = pointsLimit;
        this.changeoverSeconds = changeoverSeconds;
        this.attendancePoints = attendancePoints;
        this.teamMatchSeconds = DEFAULT_TEAM_MATCH_SECONDS;
        this.minRestSeconds = DEFAULT_MIN_REST_SECONDS;
        this.createdAt = now;
    }

    static final int DEFAULT_TEAM_MATCH_SECONDS = 180;
    static final int DEFAULT_MIN_REST_SECONDS = 30;

    /**
     * Liga Yoseikan tambo, Fase 1 (Raul, 2026-11-13): individual 1 min and 15 points end it; teams 3 min with no
     * points limit; 10 points for attending; 30 s of rest at least between two matches of a fighter. The club can
     * change all of it in the settings.
     */
    public static Event tambo(UUID ownerAccountId, UUID leagueId, String name, LocalDate eventDate, Instant now) {
        return new Event(ownerAccountId, leagueId, 1, Discipline.TAMBO, name, eventDate, 1, 60, 15, 30, 10, now);
    }

    /** The next phase of the same league, with this one's match settings. */
    public Event nextPhase(
            int phaseNumber,
            Discipline discipline,
            String name,
            LocalDate eventDate,
            int attendancePoints,
            Instant now) {
        return new Event(
                        ownerAccountId,
                        leagueId,
                        phaseNumber,
                        discipline,
                        name,
                        eventDate,
                        maxGroupsPerMat,
                        matchSeconds,
                        pointsLimit,
                        changeoverSeconds,
                        attendancePoints,
                        now)
                .withTeamRules(teamMatchSeconds, teamPointsLimit, minRestSeconds);
    }

    /** {@code teamPointsLimit}: 0 = none. */
    public Event withTeamRules(int teamMatchSeconds, int teamPointsLimit, int minRestSeconds) {
        this.teamMatchSeconds = teamMatchSeconds;
        this.teamPointsLimit = teamPointsLimit;
        this.minRestSeconds = minRestSeconds;
        return this;
    }

    public UUID getId() {
        return id;
    }

    public UUID getOwnerAccountId() {
        return ownerAccountId;
    }

    public UUID getLeagueId() {
        return leagueId;
    }

    public int getPhaseNumber() {
        return phaseNumber;
    }

    public Discipline getDiscipline() {
        return discipline;
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

    public int getTeamMatchSeconds() {
        return teamMatchSeconds;
    }

    /** 0 = no limit. */
    public int getTeamPointsLimit() {
        return teamPointsLimit;
    }

    public int matchSecondsFor(boolean teams) {
        return teams ? teamMatchSeconds : matchSeconds;
    }

    /** 0 = no limit. */
    public int pointsLimitFor(boolean teams) {
        return teams ? teamPointsLimit : pointsLimit;
    }

    public int getMinRestSeconds() {
        return minRestSeconds;
    }

    public int getChangeoverSeconds() {
        return changeoverSeconds;
    }

    public int getAttendancePoints() {
        return attendancePoints;
    }

    /** On a server that loaded it from a package: the event's id on the server it came from. */
    public UUID getOriginEventId() {
        return originEventId;
    }

    public void setOriginEventId(UUID originEventId) {
        this.originEventId = originEventId;
    }

    public String getResultsImportHash() {
        return resultsImportHash;
    }

    public void setResultsImportHash(String resultsImportHash) {
        this.resultsImportHash = resultsImportHash;
    }

    public int ageOf(LocalDate birthDate) {
        return Period.between(birthDate, eventDate).getYears();
    }

    void update(
            String name,
            LocalDate eventDate,
            int maxGroupsPerMat,
            int matchSeconds,
            int pointsLimit,
            int attendancePoints,
            int teamMatchSeconds,
            int teamPointsLimit,
            int minRestSeconds) {
        withTeamRules(teamMatchSeconds, teamPointsLimit, minRestSeconds);
        this.name = name;
        this.eventDate = eventDate;
        this.maxGroupsPerMat = maxGroupsPerMat;
        this.matchSeconds = matchSeconds;
        this.pointsLimit = pointsLimit;
        this.attendancePoints = attendancePoints;
    }
}
