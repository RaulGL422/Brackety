package dev.rgal.brackety.grouping;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "fight_match")
public class Match {

    public enum Status {
        PENDING,
        IN_PROGRESS,
        FINISHED
    }

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID eventId;
    private UUID groupId;
    private UUID matId;
    private int orderIndex;
    private UUID redParticipantId;
    private UUID blueParticipantId;
    private UUID redTeamId;
    private UUID blueTeamId;

    @Enumerated(EnumType.STRING)
    private Status status;

    private int redScore;
    private int blueScore;
    private Instant startedAt;
    private Instant finishedAt;
    private long elapsedMs;
    private Instant runningSince;
    private String disqualifiedSide;
    /** Why an offline action clashed; while set, the match takes no actions until the club reviews it. */
    private String reviewReason;

    protected Match() {}

    /** {@code red} and {@code blue} are participants, or teams when {@code teams}. */
    Match(UUID eventId, UUID groupId, UUID matId, int orderIndex, UUID red, UUID blue, boolean teams) {
        this.eventId = eventId;
        this.groupId = groupId;
        this.matId = matId;
        this.orderIndex = orderIndex;
        if (teams) {
            this.redTeamId = red;
            this.blueTeamId = blue;
        } else {
            this.redParticipantId = red;
            this.blueParticipantId = blue;
        }
        this.status = Status.PENDING;
    }

    public UUID getId() {
        return id;
    }

    public UUID getEventId() {
        return eventId;
    }

    public UUID getGroupId() {
        return groupId;
    }

    public UUID getMatId() {
        return matId;
    }

    public int getOrderIndex() {
        return orderIndex;
    }

    /** The red participant's or team's id. */
    public UUID getRedId() {
        return redTeamId != null ? redTeamId : redParticipantId;
    }

    public UUID getBlueId() {
        return blueTeamId != null ? blueTeamId : blueParticipantId;
    }

    public Status getStatus() {
        return status;
    }

    public int getRedScore() {
        return redScore;
    }

    public int getBlueScore() {
        return blueScore;
    }

    public Instant getStartedAt() {
        return startedAt;
    }

    public Instant getFinishedAt() {
        return finishedAt;
    }

    /** "RED", "BLUE" or null. */
    public String getDisqualifiedSide() {
        return disqualifiedSide;
    }

    /** Copies the scoreboard's state after each event, so mats and rankings need not replay them. */
    public void updateFromScoreboard(
            int redScore,
            int blueScore,
            Duration elapsed,
            Instant runningSince,
            String disqualifiedSide,
            boolean finished,
            Instant now) {
        this.redScore = redScore;
        this.blueScore = blueScore;
        this.elapsedMs = elapsed.toMillis();
        this.runningSince = runningSince;
        this.disqualifiedSide = disqualifiedSide;
        if (startedAt == null) {
            startedAt = now;
        }
        status = finished ? Status.FINISHED : Status.IN_PROGRESS;
        if (finished) {
            finishedAt = now;
        }
    }

    /** Back to pending, as if never started: the superadmin restarts it (its actions go with it). */
    public void reset() {
        status = Status.PENDING;
        redScore = 0;
        blueScore = 0;
        startedAt = null;
        finishedAt = null;
        elapsedMs = 0;
        runningSince = null;
        disqualifiedSide = null;
        reviewReason = null;
    }

    public String getReviewReason() {
        return reviewReason;
    }

    public boolean isInReview() {
        return reviewReason != null;
    }

    public void putInReview(String reason) {
        reviewReason = reason;
    }

    public void endReview() {
        reviewReason = null;
    }

    Duration clockLeft(Instant now, Duration length) {
        var elapsed = Duration.ofMillis(elapsedMs);
        if (runningSince != null) {
            elapsed = elapsed.plus(Duration.between(runningSince, now));
        }
        var left = length.minus(elapsed);
        return left.isNegative() ? Duration.ZERO : left;
    }
}
