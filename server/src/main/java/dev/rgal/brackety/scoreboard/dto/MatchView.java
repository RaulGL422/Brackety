package dev.rgal.brackety.scoreboard.dto;

import dev.rgal.brackety.grouping.Match;
import dev.rgal.brackety.scoreboard.MatchEventType;
import dev.rgal.brackety.scoreboard.Side;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * A match as the scoreboard shows it. The client counts {@code remainingMs} down while
 * {@code running} and resyncs on every poll. {@code endReason}: POINTS, TIME, DISQUALIFICATION or null.
 */
public record MatchView(
        UUID id,
        UUID matId,
        int matNumber,
        int groupNumber,
        Match.Status status,
        int lengthSeconds,
        int pointsLimit,
        long remainingMs,
        boolean running,
        String endReason,
        Corner red,
        Corner blue,
        List<TimelineEntry> timeline) {

    /** {@code oneHandRule}: the fighter is 4 to 7, so the one-hand warning applies. */
    public record Corner(
            UUID participantId,
            String name,
            boolean ghost,
            boolean oneHandRule,
            int points,
            int warnings,
            int oneHandWarnings,
            boolean disqualified) {}

    /** {@code gaveRivalPoint}: a second one-hand warning that gave the rival a point. */
    public record TimelineEntry(
            UUID id,
            MatchEventType type,
            Side side,
            String reason,
            String actor,
            Instant at,
            long clockMs,
            boolean automatic,
            boolean undone,
            boolean gaveRivalPoint) {}
}
