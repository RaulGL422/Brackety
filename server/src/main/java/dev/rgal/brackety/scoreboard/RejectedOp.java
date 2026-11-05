package dev.rgal.brackety.scoreboard;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** A device action the server did not apply; kept as the import log until and after the club's review. */
@Entity
@Table(name = "offline_rejected_op")
class RejectedOp {

    enum Cause {
        /** The device did not know every action the server had. */
        KNOWN_EVENTS,
        RULES,
        /** A one-hand warning for a fighter who is not 4 to 7. */
        AGE,
        MAT_BUSY,
        FIGHTER_BUSY,
        /** It arrived while the match was already waiting for the review. */
        IN_REVIEW
    }

    enum Resolution {
        APPLIED,
        /** The club applied the review, but the rules refused this action. */
        SKIPPED,
        DISCARDED
    }

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID matchId;
    private int position;
    private UUID opId;

    @Enumerated(EnumType.STRING)
    private MatchEventType type;

    @Enumerated(EnumType.STRING)
    private Side side;

    private String reason;
    private Instant at;
    private UUID actorAccountId;

    @Enumerated(EnumType.STRING)
    private Cause cause;

    @Enumerated(EnumType.STRING)
    private Resolution resolution;

    private UUID resolvedBy;
    private Instant resolvedAt;
    /** When it arrived. */
    private Instant createdAt;

    protected RejectedOp() {}

    RejectedOp(UUID matchId, int position, MatchWriter.Action action, Instant at, Cause cause, Instant createdAt) {
        this.matchId = matchId;
        this.position = position;
        this.opId = action.opId();
        this.type = action.type();
        this.side = action.side();
        this.reason = action.reason();
        this.at = at;
        this.actorAccountId = action.actorAccountId();
        this.cause = cause;
        this.createdAt = createdAt;
    }

    void resolve(Resolution resolution, UUID by, Instant at) {
        this.resolution = resolution;
        this.resolvedBy = by;
        this.resolvedAt = at;
    }

    MatchWriter.Action action() {
        return new MatchWriter.Action(type, side, reason, opId, actorAccountId);
    }

    UUID getOpId() {
        return opId;
    }

    MatchEventType getType() {
        return type;
    }

    Side getSide() {
        return side;
    }

    String getReason() {
        return reason;
    }

    Instant getAt() {
        return at;
    }

    UUID getActorAccountId() {
        return actorAccountId;
    }

    Cause getCause() {
        return cause;
    }

    Resolution getResolution() {
        return resolution;
    }

    Instant getCreatedAt() {
        return createdAt;
    }
}
