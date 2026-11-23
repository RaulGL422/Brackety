package dev.rgal.brackety.event;

import dev.rgal.brackety.event.sport.SportVersion;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import java.time.Instant;
import java.time.LocalDate;
import java.time.Period;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.UUID;
import org.hibernate.annotations.BatchSize;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Its match rules live in its modalities ({@link Modality}), never here. */
@Entity
public class Event {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID ownerAccountId;
    private UUID leagueId;
    private int phaseNumber;

    /** The sport's version it plays (docs/producto/plantillas-deporte.md). */
    @ManyToOne(fetch = FetchType.EAGER, optional = false)
    private SportVersion sportVersion;

    private String name;
    private LocalDate eventDate;
    private int attendancePoints;
    private Instant createdAt;
    private UUID originEventId;

    /** The event's own choice; null follows its sport. */
    @Enumerated(EnumType.STRING)
    private MeasureRequirement weightRequirement;

    @Enumerated(EnumType.STRING)
    private MeasureRequirement heightRequirement;

    /** The event's own list; null follows its sport. */
    @JdbcTypeCode(SqlTypes.ARRAY)
    private List<String> warningReasons;

    private String resultsImportHash;

    /** F1-7: groups and scoring only between start and finish; finished, read-only until the club reopens it. */
    private Instant startedAt;

    private Instant finishedAt;
    private Instant autoCloseWarnedAt;

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
            SportVersion sport,
            String name,
            LocalDate eventDate,
            int attendancePoints,
            Modality modality,
            Instant now) {
        this.ownerAccountId = ownerAccountId;
        this.leagueId = leagueId;
        this.phaseNumber = phaseNumber;
        this.sportVersion = sport;
        this.name = name;
        this.eventDate = eventDate;
        this.attendancePoints = attendancePoints;
        this.modalities.add(modality);
        this.createdAt = now;
    }

    /**
     * The next phase of the same league. In the same sport it keeps this one's match rules, measures asked and warning
     * reasons; in another sport it starts from that sport's (a tambo phase does not hand its rules to grappling).
     */
    public Event nextPhase(
            int phaseNumber, SportVersion sport, String name, LocalDate eventDate, int attendancePoints, Instant now) {
        var same = sport.sameSport(sportVersion);
        var next = new Event(
                ownerAccountId,
                leagueId,
                phaseNumber,
                same ? sportVersion : sport,
                name,
                eventDate,
                attendancePoints,
                same ? modality().copy() : sport.rules().modality(),
                now);
        if (same) {
            next.setMeasureRequirements(weightRequirement, heightRequirement);
            next.warningReasons = warningReasons == null ? null : List.copyOf(warningReasons);
        }
        return next;
    }

    public enum PhaseState {
        NOT_STARTED,
        IN_PROGRESS,
        FINISHED
    }

    public PhaseState phaseState() {
        if (finishedAt != null) {
            return PhaseState.FINISHED;
        }
        return startedAt == null ? PhaseState.NOT_STARTED : PhaseState.IN_PROGRESS;
    }

    public Instant getStartedAt() {
        return startedAt;
    }

    public Instant getFinishedAt() {
        return finishedAt;
    }

    public Instant getAutoCloseWarnedAt() {
        return autoCloseWarnedAt;
    }

    void start(Instant now) {
        startedAt = now;
    }

    /** Results played elsewhere (the hall's laptop) came in: the phase started with their first group. */
    public void startedElsewhere(Instant firstGroupAt) {
        if (startedAt == null) {
            startedAt = firstGroupAt;
        }
    }

    void finish(Instant now) {
        finishedAt = now;
    }

    /** Back in progress; a later day without finishing warns again. */
    void reopen() {
        finishedAt = null;
        autoCloseWarnedAt = null;
    }

    void autoCloseWarned(Instant now) {
        autoCloseWarnedAt = now;
    }

    /** Whether weight is asked: the event's own choice, or its sport's. */
    public MeasureRequirement weightRequirement() {
        return weightRequirement != null
                ? weightRequirement
                : sportVersion.rules().weight();
    }

    public MeasureRequirement heightRequirement() {
        return heightRequirement != null
                ? heightRequirement
                : sportVersion.rules().height();
    }

    /** Null: as the sport says. */
    public MeasureRequirement getOwnWeightRequirement() {
        return weightRequirement;
    }

    public MeasureRequirement getOwnHeightRequirement() {
        return heightRequirement;
    }

    /** What the referee picks from: the event's own list, or its sport's. */
    public List<String> warningReasons() {
        return warningReasons != null
                ? List.copyOf(warningReasons)
                : sportVersion.rules().warningReasons();
    }

    /** Null: as the sport says. */
    public List<String> getOwnWarningReasons() {
        return warningReasons == null ? null : List.copyOf(warningReasons);
    }

    /** Null follows the sport. Trimmed, without blanks nor repeats (case aside), in the order given. */
    public void setWarningReasons(List<String> reasons) {
        if (reasons == null) {
            warningReasons = null;
            return;
        }
        var unique = new LinkedHashMap<String, String>();
        reasons.stream()
                .map(String::strip)
                .filter(r -> !r.isEmpty())
                .forEach(r -> unique.putIfAbsent(r.toLowerCase(), r));
        warningReasons = new ArrayList<>(unique.values());
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

    public SportVersion getSport() {
        return sportVersion;
    }

    public String getName() {
        return name;
    }

    public LocalDate getEventDate() {
        return eventDate;
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
            int attendancePoints,
            Modality.FormatRules individual,
            Modality.FormatRules team,
            int minRestSeconds,
            int superiorityGap) {
        this.name = name;
        this.eventDate = eventDate;
        this.attendancePoints = attendancePoints;
        modality().update(individual, team, minRestSeconds, superiorityGap);
    }
}
