package dev.rgal.brackety.scoreboard;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

@Entity
public class MatchEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID matchId;
    private int position;

    @Enumerated(EnumType.STRING)
    private MatchEventType type;

    @Enumerated(EnumType.STRING)
    private Side side;

    private String reason;
    private UUID targetEventId;
    private UUID actorAccountId;
    /** Added by the server, not by the referee: the stop when the match ends by points or disqualification. */
    private boolean automatic;

    private Instant at;
    private long clockMs;
    /** The device's id for an action sent from the Android queue; null from the web. */
    private UUID opId;
    /** For a CLOCK_ADJUST, the time added to the clock (negative: taken away); else null. */
    private Long deltaMs;

    protected MatchEvent() {}

    MatchEvent(
            UUID matchId,
            int position,
            MatchEventType type,
            Side side,
            String reason,
            UUID targetEventId,
            UUID actorAccountId,
            boolean automatic,
            Instant at,
            Duration clock,
            UUID opId,
            Long deltaMs) {
        this.matchId = matchId;
        this.position = position;
        this.type = type;
        this.side = side;
        this.reason = reason;
        this.targetEventId = targetEventId;
        this.actorAccountId = actorAccountId;
        this.automatic = automatic;
        this.at = at;
        this.clockMs = clock.toMillis();
        this.opId = opId;
        this.deltaMs = deltaMs;
    }

    public UUID getId() {
        return id;
    }

    public UUID getOpId() {
        return opId;
    }

    public UUID getMatchId() {
        return matchId;
    }

    public MatchEventType getType() {
        return type;
    }

    public Side getSide() {
        return side;
    }

    public String getReason() {
        return reason;
    }

    public UUID getTargetEventId() {
        return targetEventId;
    }

    public UUID getActorAccountId() {
        return actorAccountId;
    }

    public boolean isAutomatic() {
        return automatic;
    }

    public Instant getAt() {
        return at;
    }

    public long getClockMs() {
        return clockMs;
    }

    public Long getDeltaMs() {
        return deltaMs;
    }

    TamboMatch.Entry toEntry() {
        return new TamboMatch.Entry(id, type, side, at, targetEventId, deltaMs == null ? 0 : deltaMs);
    }
}
