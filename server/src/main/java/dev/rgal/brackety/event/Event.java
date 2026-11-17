package dev.rgal.brackety.event;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import java.time.Instant;
import java.time.LocalDate;
import java.time.Period;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.hibernate.annotations.BatchSize;

/** Its match rules live in its modalities ({@link Modality}), never here. */
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
    private int attendancePoints;
    private Instant createdAt;
    private UUID originEventId;

    /** The event's own choice; null follows its sport. */
    @Enumerated(EnumType.STRING)
    private MeasureRequirement weightRequirement;

    @Enumerated(EnumType.STRING)
    private MeasureRequirement heightRequirement;

    private String resultsImportHash;

    @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    @JoinColumn(name = "event_id", nullable = false)
    @OrderBy("position")
    @BatchSize(size = 50)
    private List<Modality> modalities = new ArrayList<>();

    protected Event() {}

    public Event(
            UUID ownerAccountId,
            UUID leagueId,
            int phaseNumber,
            Discipline discipline,
            String name,
            LocalDate eventDate,
            int maxGroupsPerMat,
            int attendancePoints,
            Modality modality,
            Instant now) {
        this.ownerAccountId = ownerAccountId;
        this.leagueId = leagueId;
        this.phaseNumber = phaseNumber;
        this.discipline = discipline;
        this.name = name;
        this.eventDate = eventDate;
        this.maxGroupsPerMat = maxGroupsPerMat;
        this.attendancePoints = attendancePoints;
        this.modalities.add(modality);
        this.createdAt = now;
    }

    /** Liga Yoseikan tambo, Fase 1: 10 points for attending; its match rules in {@link Modality#tambo()}. */
    public static Event tambo(UUID ownerAccountId, UUID leagueId, String name, LocalDate eventDate, Instant now) {
        return new Event(ownerAccountId, leagueId, 1, Discipline.TAMBO, name, eventDate, 1, 10, Modality.tambo(), now);
    }

    /** The next phase of the same league, with this one's match rules and measures asked. */
    public Event nextPhase(
            int phaseNumber,
            Discipline discipline,
            String name,
            LocalDate eventDate,
            int attendancePoints,
            Instant now) {
        var next = new Event(
                ownerAccountId,
                leagueId,
                phaseNumber,
                discipline,
                name,
                eventDate,
                maxGroupsPerMat,
                attendancePoints,
                modality().copy(),
                now);
        next.setMeasureRequirements(weightRequirement, heightRequirement);
        return next;
    }

    /** Whether weight is asked: the event's own choice, or its sport's. */
    public MeasureRequirement weightRequirement() {
        return weightRequirement != null ? weightRequirement : discipline.weight();
    }

    public MeasureRequirement heightRequirement() {
        return heightRequirement != null ? heightRequirement : discipline.height();
    }

    /** Null: as the sport says. */
    public MeasureRequirement getOwnWeightRequirement() {
        return weightRequirement;
    }

    public MeasureRequirement getOwnHeightRequirement() {
        return heightRequirement;
    }

    /** Null follows the sport. */
    public void setMeasureRequirements(MeasureRequirement weight, MeasureRequirement height) {
        this.weightRequirement = weight;
        this.heightRequirement = height;
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

    /** Its only modality for now; the competition of 2026-12-20 will bring several. */
    public Modality modality() {
        return modalities.getFirst();
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
            int attendancePoints,
            Modality.FormatRules individual,
            Modality.FormatRules team,
            int minRestSeconds) {
        this.name = name;
        this.eventDate = eventDate;
        this.maxGroupsPerMat = maxGroupsPerMat;
        this.attendancePoints = attendancePoints;
        modality().update(individual, team, minRestSeconds);
    }
}
