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

    @Enumerated(EnumType.STRING)
    private Status status;

    private int redScore;
    private int blueScore;
    private Instant startedAt;
    private Instant finishedAt;

    protected Match() {}

    Match(UUID eventId, UUID groupId, UUID matId, int orderIndex, UUID red, UUID blue) {
        this.eventId = eventId;
        this.groupId = groupId;
        this.matId = matId;
        this.orderIndex = orderIndex;
        this.redParticipantId = red;
        this.blueParticipantId = blue;
        this.status = Status.PENDING;
    }

    public UUID getId() {
        return id;
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

    public UUID getRedParticipantId() {
        return redParticipantId;
    }

    public UUID getBlueParticipantId() {
        return blueParticipantId;
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

    public Instant getFinishedAt() {
        return finishedAt;
    }

    public boolean involves(UUID participantId) {
        return redParticipantId.equals(participantId) || blueParticipantId.equals(participantId);
    }

    // Without pauses yet: the scoreboard (next step) replaces this with its own match clock.
    Duration clockLeft(Instant now, Duration length) {
        var left = length.minus(Duration.between(startedAt, now));
        return left.isNegative() ? Duration.ZERO : left;
    }
}
