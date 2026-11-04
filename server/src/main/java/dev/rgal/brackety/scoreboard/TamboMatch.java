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
 * State of a tambo match rebuilt from its events in order (reglamento Yoseikan, cap. 3.1): clock,
 * points, warnings and how it ended. Undone events are skipped, so an undo never loses the trail.
 */
final class TamboMatch {

    enum EndReason {
        POINTS,
        TIME,
        DISQUALIFICATION
    }

    record Rules(Duration length, int pointsLimit) {}

    /** {@code target}: for an UNDO, the event it undoes. */
    record Entry(UUID id, MatchEventType type, Side side, Instant at, UUID target) {}

    /** Points include those given for the rival's one-hand warnings. */
    record Corner(int points, int warnings, int oneHandWarnings) {}

    private static final class Tally {
        int points;
        int warnings;
        int oneHandWarnings;
    }

    private final Rules rules;
    private final Map<Side, Tally> tallies = new EnumMap<>(Side.class);
    private final Set<UUID> autoPointWarnings = new HashSet<>();
    private Duration elapsed = Duration.ZERO;
    private Instant runningSince;
    private Side disqualified;
    private boolean started;
    private boolean finished;
    private Entry lastUndoable;

    private TamboMatch(Rules rules) {
        this.rules = rules;
        for (var side : Side.values()) {
            tallies.put(side, new Tally());
        }
    }

    static TamboMatch replay(Rules rules, List<Entry> entries) {
        var match = new TamboMatch(rules);
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
            case POINT -> {
                tallies.get(e.side()).points++;
                lastUndoable = e;
            }
            case WARNING -> {
                tallies.get(e.side()).warnings++;
                lastUndoable = e;
            }
            case ONE_HAND_WARNING -> {
                // Every second one-hand warning gives the rival a point.
                if (++tallies.get(e.side()).oneHandWarnings % 2 == 0) {
                    tallies.get(e.side().opponent()).points++;
                    autoPointWarnings.add(e.id());
                }
                lastUndoable = e;
            }
            case DISQUALIFICATION -> {
                disqualified = e.side();
                lastUndoable = e;
            }
            case FINISH -> finished = true;
            case UNDO -> throw new IllegalArgumentException("UNDO entries are never applied");
        }
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
            return Optional.of(EndReason.DISQUALIFICATION);
        }
        if (tallies.values().stream().anyMatch(t -> t.points >= rules.pointsLimit())) {
            return Optional.of(EndReason.POINTS);
        }
        return remainingAt(now).isZero() ? Optional.of(EndReason.TIME) : Optional.empty();
    }

    Corner corner(Side side) {
        var t = tallies.get(side);
        return new Corner(t.points, t.warnings, t.oneHandWarnings);
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

    boolean gaveAutoPoint(UUID oneHandWarningId) {
        return autoPointWarnings.contains(oneHandWarningId);
    }

    /** Why {@code type} cannot happen now, or empty if it can. Checks only the match itself. */
    Optional<String> refuse(MatchEventType type, Instant now) {
        if (finished) {
            return Optional.of("The match is finished.");
        }
        var over = endReason(now).isPresent();
        String reason = switch (type) {
            case START -> over ? "The match is over." : isRunning(now) ? "The clock is already running." : null;
            case STOP -> isRunning(now) ? null : "The clock is not running.";
            case POINT, WARNING, ONE_HAND_WARNING, DISQUALIFICATION -> over ? "The match is over." : null;
            case UNDO -> lastUndoable == null ? "Nothing to undo." : null;
            case FINISH -> over ? null : "The match is not over yet.";
        };
        return Optional.ofNullable(reason);
    }
}
