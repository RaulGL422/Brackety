package dev.rgal.brackety.scoreboard;

import java.time.Duration;
import java.time.Instant;
import java.util.EnumMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * State of a match rebuilt from its events in order: clock, points, warnings and how it ended, by the rules of its
 * sport ({@link MatchRules}). Undone events are skipped, so an undo never loses the trail.
 */
final class MatchState {

    /** What a disqualification gives the rival when there is no points limit, at least. */
    static final int DISQUALIFICATION_POINTS = 15;

    /**
     * {@code target}: for an UNDO, the event it undoes. {@code deltaMs}: for a CLOCK_ADJUST, the time added.
     * {@code value}: for a POINT or POINT_REMOVED, how many points (1 to the sport's most).
     */
    record Entry(UUID id, MatchEventType type, Side side, Instant at, UUID target, long deltaMs, int value) {

        Entry(UUID id, MatchEventType type, Side side, Instant at, UUID target, long deltaMs) {
            this(id, type, side, at, target, deltaMs, 1);
        }

        Entry(UUID id, MatchEventType type, Side side, Instant at, UUID target) {
            this(id, type, side, at, target, 0);
        }
    }

    /**
     * Points include those given for the rival's warnings. When the sport says so, a disqualification is scored as 0
     * for the disqualified fighter and the points limit for the rival, or, with no limit, the rival's points but at
     * least {@value #DISQUALIFICATION_POINTS}.
     */
    record Corner(int points, int warnings, int oneHandWarnings) {}

    private final MatchRules rules;
    private final Map<Side, CornerTally> tallies = new EnumMap<>(Side.class);
    private final Set<UUID> autoPointWarnings = new HashSet<>();
    private Duration elapsed = Duration.ZERO;
    private Instant runningSince;
    private Side disqualified;
    private boolean disqualifiedByWarnings;
    private Side submittedBy;
    private Side extraTimeWinner;
    private boolean started;
    private boolean finished;
    private Entry lastUndoable;
    // How many points have been scored, to know who scored last.
    private int scored;

    private MatchState(MatchRules rules) {
        this.rules = rules;
        for (var side : Side.values()) {
            tallies.put(side, new CornerTally());
        }
    }

    static MatchState replay(MatchRules rules, List<Entry> entries) {
        var match = new MatchState(rules);
        var undone = new HashSet<UUID>();
        entries.stream().filter(e -> e.type() == MatchEventType.UNDO).forEach(e -> undone.add(e.target()));
        entries.stream()
                .filter(e -> e.type() != MatchEventType.UNDO && !undone.contains(e.id()))
                .forEach(match::apply);
        return match;
    }

    private void apply(Entry e) {
        switch (e.type()) {
            case START -> {
                started = true;
                if (runningSince == null) {
                    runningSince = e.at();
                }
            }
            case STOP -> {
                elapsed = elapsedAt(e.at());
                runningSince = null;
            }
            // Only on a stopped clock; one that ran out of time stays stopped after the adjustment.
            case CLOCK_ADJUST -> {
                elapsed = adjusted(elapsedAt(e.at()), e.deltaMs());
                runningSince = null;
            }
            case POINT -> tallies.get(e.side()).score(e.value(), ++scored);
            case POINT_REMOVED -> tallies.get(e.side()).takeBack(e.value());
            case WARNING -> warn(e);
            case ONE_HAND_WARNING -> {
                if (++tallies.get(e.side()).oneHandWarnings % 2 == 0) {
                    givePointsToRival(e, 1);
                }
            }
            case DISQUALIFICATION -> {
                disqualified = e.side();
                disqualifiedByWarnings = false;
            }
            case SUBMISSION -> submittedBy = e.side();
            case EXTRA_TIME -> extraTimeWinner = e.side();
            case FINISH -> finished = true;
            case CANCEL -> cancel();
            case REOPEN -> finished = false;
            case UNDO -> throw new IllegalArgumentException("UNDO entries are never applied");
        }
        if (e.type().undoable()) {
            lastUndoable = e;
        }
    }

    // Tambo: every second warning gives the rival a point (Raul, 2026-11-13); grappling: every one, and the 4th
    // disqualifies.
    private void warn(Entry e) {
        var warnings = ++tallies.get(e.side()).warnings;
        var points = rules.scoring().warningPoints(warnings);
        if (points > 0) {
            givePointsToRival(e, points);
        }
        if (warnings == rules.scoring().warningsToDisqualify()) {
            disqualified = e.side();
            disqualifiedByWarnings = true;
        }
    }

    private void givePointsToRival(Entry warning, int points) {
        tallies.get(warning.side().opponent()).points += points;
        autoPointWarnings.add(warning.id());
    }

    // As if it had never started: nothing before it can be undone either.
    private void cancel() {
        tallies.values().forEach(CornerTally::clear);
        autoPointWarnings.clear();
        elapsed = Duration.ZERO;
        runningSince = null;
        disqualified = null;
        disqualifiedByWarnings = false;
        submittedBy = null;
        extraTimeWinner = null;
        started = false;
        scored = 0;
        lastUndoable = null;
    }

    // Adding time to the clock takes it off the elapsed time, never below 0 nor beyond the match length.
    private Duration adjusted(Duration elapsedNow, long deltaMs) {
        var result = elapsedNow.minusMillis(deltaMs);
        if (result.isNegative()) {
            return Duration.ZERO;
        }
        return result.compareTo(rules.length()) > 0 ? rules.length() : result;
    }

    // An adjustment must change the clock and never leave it at 0: the time runs out only by running.
    boolean cannotAdjust(Instant now, long deltaMs) {
        var result = adjusted(elapsedAt(now), deltaMs);
        return result.equals(elapsedAt(now)) || result.equals(rules.length());
    }

    Duration elapsedAt(Instant now) {
        var total = runningSince == null ? elapsed : elapsed.plus(Duration.between(runningSince, now));
        return total.compareTo(rules.length()) > 0 ? rules.length() : total;
    }

    Duration remainingAt(Instant now) {
        return rules.length().minus(elapsedAt(now));
    }

    /** True while the clock runs; it stops by itself when the time is over. */
    boolean isRunning(Instant now) {
        return runningSince != null && remainingAt(now).isPositive();
    }

    Optional<EndReason> endReason(Instant now) {
        if (disqualified != null) {
            return Optional.of(disqualifiedByWarnings ? EndReason.WARNINGS : EndReason.DISQUALIFICATION);
        }
        if (submittedBy != null) {
            return Optional.of(EndReason.SUBMISSION);
        }
        if (extraTimeWinner != null) {
            return Optional.of(EndReason.EXTRA_TIME);
        }
        if (rules.hasLimit() && tallies.values().stream().anyMatch(t -> t.points >= rules.pointsLimit())) {
            return Optional.of(EndReason.POINTS);
        }
        var gap = rules.scoring().superiorityGap();
        if (gap > 0 && Math.abs(tallied(Side.RED) - tallied(Side.BLUE)) >= gap) {
            return Optional.of(EndReason.SUPERIORITY);
        }
        return remainingAt(now).isZero() ? Optional.of(EndReason.TIME) : Optional.empty();
    }

    /**
     * Who won, once the match is over; empty while it goes on, on a draw (tambo) or while a tie waits for the extra
     * time (grappling, art. 31).
     */
    Optional<Side> winner(Instant now) {
        return endReason(now).flatMap(end -> switch (end) {
            case DISQUALIFICATION, WARNINGS -> Optional.of(disqualified.opponent());
            case SUBMISSION -> Optional.of(submittedBy);
            case EXTRA_TIME -> Optional.of(extraTimeWinner);
            case POINTS, SUPERIORITY, TIME -> onPoints();
        });
    }

    // More points; on a tie, the sport's tiebreakers (CornerTally).
    private Optional<Side> onPoints() {
        var lead = CornerTally.compare(
                tallies.get(Side.RED), tallies.get(Side.BLUE), rules.scoring().tiebreaks());
        return lead == 0 ? Optional.empty() : Optional.of(lead > 0 ? Side.RED : Side.BLUE);
    }

    /** The time ended on a tie that no tiebreaker settles: only the extra time decides (grappling, art. 32). */
    boolean needsExtraTime(Instant now) {
        return rules.scoring().hasExtraTime()
                && endReason(now).filter(r -> r == EndReason.TIME).isPresent()
                && winner(now).isEmpty();
    }

    Corner corner(Side side) {
        var t = tallies.get(side);
        return new Corner(points(side), t.warnings, t.oneHandWarnings);
    }

    // The points the fighter had stay in the tally, so undoing the disqualification gives them back.
    private int points(Side side) {
        if (disqualified != null && rules.scoring().disqualificationScores()) {
            if (disqualified == side) {
                return 0;
            }
            return rules.hasLimit() ? rules.pointsLimit() : Math.max(tallied(side), DISQUALIFICATION_POINTS);
        }
        return tallied(side);
    }

    /** The points a fighter scored and got for the rival's warnings, whatever a disqualification shows. */
    int tallied(Side side) {
        return tallies.get(side).points;
    }

    /** A disqualification, a submission or the extra time decided it: no points move it any more. */
    boolean isDecided() {
        return disqualified != null || submittedBy != null || extraTimeWinner != null;
    }

    MatchRules rules() {
        return rules;
    }

    Side disqualified() {
        return disqualified;
    }

    boolean isStarted() {
        return started;
    }

    boolean isFinished() {
        return finished;
    }

    Optional<Entry> lastUndoable() {
        return Optional.ofNullable(lastUndoable);
    }

    /** True for a warning (of either kind) that gave the rival a point. */
    boolean gaveAutoPoint(UUID warningId) {
        return autoPointWarnings.contains(warningId);
    }

    /** Why {@code type} cannot happen now, or empty if it can ({@link MatchRefusals}). */
    Optional<String> refuse(MatchEventType type, Instant now) {
        return refuse(type, null, 0, 1, now);
    }

    Optional<String> refuse(MatchEventType type, Side side, long deltaMs, Instant now) {
        return refuse(type, side, deltaMs, 1, now);
    }

    Optional<String> refuse(MatchEventType type, Side side, long deltaMs, int value, Instant now) {
        return MatchRefusals.of(this, type, side, deltaMs, value, now);
    }
}
