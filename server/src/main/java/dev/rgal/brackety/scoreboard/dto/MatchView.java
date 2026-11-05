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
 * {@code serverTime}: the instant the view is computed at, so the device can correct its clock.
 * {@code review}: null unless an offline action clashed and the club has to review it.
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
        List<TimelineEntry> timeline,
        Instant serverTime,
        Review review) {

    /**
     * A participant ({@code participantId}) or a team ({@code teamId}, {@code teamNumber}); {@code members}
     * are the team's names, or the participant's own. {@code oneHandRule}: the fighter (or someone in
     * the team) is 4 to 7, so the one-hand warning applies.
     */
    public record Corner(
            UUID participantId,
            String name,
            boolean ghost,
            boolean oneHandRule,
            int points,
            int warnings,
            int oneHandWarnings,
            boolean disqualified,
            UUID teamId,
            Integer teamNumber,
            List<String> members) {}

    /** {@code gaveRivalPoint}: a second one-hand warning that gave the rival a point. {@code opId}: the device action it came from, or null. */
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
            boolean gaveRivalPoint,
            UUID opId) {}

    /**
     * {@code reason}: why the first action clashed (KNOWN_EVENTS, RULES, AGE, MAT_BUSY, FIGHTER_BUSY).
     * {@code ops}: the actions the device sent since, in arrival order.
     */
    public record Review(String reason, List<ReviewOp> ops) {}

    /** {@code reason}: the warning's or disqualification's; {@code cause}: why it was not applied. */
    public record ReviewOp(
            UUID opId,
            MatchEventType type,
            Side side,
            String reason,
            String actor,
            Instant at,
            Instant receivedAt,
            String cause) {}
}
