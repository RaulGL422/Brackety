package dev.rgal.brackety.scoreboard;

import dev.rgal.brackety.scoreboard.MatchState.EndReason;
import java.time.Instant;
import java.util.Optional;

/**
 * Why an action cannot happen now, by the match and its rules only; {@link MatchWriter} adds the mat, the rest and
 * the age. The app words the same refusals in {@code MatchRefusal} (spec/scoring).
 */
final class MatchRefusals {

    static final String NOT_STARTED = "The match has not started: press Start first.";
    static final String OVER = "The match is over.";
    private static final String NO_POINTS = "No points to take back.";

    private MatchRefusals() {}

    /** {@code side}: for a point removed; {@code deltaMs}: for a clock adjustment; {@code value}: for points. */
    static Optional<String> of(MatchState match, MatchEventType type, Side side, long deltaMs, int value, Instant now) {
        if (match.isFinished()) {
            return Optional.ofNullable(type == MatchEventType.REOPEN ? null : "The match is finished.");
        }
        var scoring = match.rules().scoring();
        var notInThisSport = switch (type) {
            case ONE_HAND_WARNING -> !scoring.oneHandWarnings();
            case SUBMISSION -> !scoring.submissions();
            case EXTRA_TIME -> !scoring.tiebreaks();
            default -> false;
        };
        if (notInThisSport) {
            return Optional.of("Not in this sport.");
        }
        if ((type == MatchEventType.POINT || type == MatchEventType.POINT_REMOVED)
                && (value < 1 || value > scoring.maxPointValue())) {
            return Optional.of("This sport has no such value.");
        }
        return Optional.ofNullable(byState(match, type, side, deltaMs, value, now));
    }

    private static String byState(
            MatchState match, MatchEventType type, Side side, long deltaMs, int value, Instant now) {
        var end = match.endReason(now);
        var over = end.isPresent();
        // The time ended the match, but the last action's point may still come (tambo, F1-3).
        var overButTime = end.filter(r -> r != EndReason.TIME).isPresent();
        var started = match.isStarted();
        return switch (type) {
            case START -> over ? OVER : match.isRunning(now) ? "The clock is already running." : null;
            case STOP -> match.isRunning(now) ? null : "The clock is not running.";
            case POINT ->
                (match.rules().scoring().pointsAfterTime() ? overButTime : over) ? OVER : started ? null : NOT_STARTED;
            case WARNING, ONE_HAND_WARNING, DISQUALIFICATION, SUBMISSION -> over ? OVER : started ? null : NOT_STARTED;
            // A correction: also once the time or the points ended the match, which it may reopen.
            case POINT_REMOVED ->
                !started
                        ? NOT_STARTED
                        : match.isDecided() ? OVER : side != null && match.tallied(side) < value ? NO_POINTS : null;
            case CLOCK_ADJUST ->
                match.isRunning(now)
                        ? "Stop the clock first."
                        : overButTime ? OVER : match.cannotAdjust(now, deltaMs) ? "The clock cannot go further." : null;
            case EXTRA_TIME -> match.needsExtraTime(now) ? null : "No extra time: the match is not tied at the end.";
            case UNDO -> match.lastUndoable().isEmpty() ? "Nothing to undo." : null;
            case FINISH ->
                !over
                        ? "The match is not over yet."
                        : match.needsExtraTime(now) ? "Tied after every tiebreaker: play the extra time first." : null;
            case CANCEL -> started ? null : NOT_STARTED;
            case REOPEN -> "The match is not finished.";
        };
    }
}
