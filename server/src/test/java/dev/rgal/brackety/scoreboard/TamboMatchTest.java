package dev.rgal.brackety.scoreboard;

import static dev.rgal.brackety.scoreboard.MatchEventType.CLOCK_ADJUST;
import static dev.rgal.brackety.scoreboard.MatchEventType.DISQUALIFICATION;
import static dev.rgal.brackety.scoreboard.MatchEventType.FINISH;
import static dev.rgal.brackety.scoreboard.MatchEventType.ONE_HAND_WARNING;
import static dev.rgal.brackety.scoreboard.MatchEventType.POINT;
import static dev.rgal.brackety.scoreboard.MatchEventType.POINT_REMOVED;
import static dev.rgal.brackety.scoreboard.MatchEventType.START;
import static dev.rgal.brackety.scoreboard.MatchEventType.STOP;
import static dev.rgal.brackety.scoreboard.MatchEventType.UNDO;
import static dev.rgal.brackety.scoreboard.MatchEventType.WARNING;
import static dev.rgal.brackety.scoreboard.Side.BLUE;
import static dev.rgal.brackety.scoreboard.Side.RED;
import static org.assertj.core.api.Assertions.assertThat;

import dev.rgal.brackety.scoreboard.TamboMatch.Corner;
import dev.rgal.brackety.scoreboard.TamboMatch.EndReason;
import dev.rgal.brackety.scoreboard.TamboMatch.Entry;
import dev.rgal.brackety.scoreboard.TamboMatch.Rules;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class TamboMatchTest {

    private static final Instant T0 = Instant.parse("2027-03-10T09:00:00Z");
    private static final Rules RULES = new Rules(Duration.ofMinutes(2), 15);

    private final List<Entry> entries = new ArrayList<>();

    @Test
    void theClockOnlyRunsBetweenStartAndStop() {
        add(START, null, 0);
        add(STOP, null, 30);
        add(START, null, 50);

        var match = replay();

        assertThat(match.remainingAt(at(60))).isEqualTo(Duration.ofSeconds(80));
        assertThat(match.isRunning(at(60))).isTrue();
        assertThat(match.endReason(at(60))).isEmpty();
        assertThat(match.refuse(START, at(60))).contains("The clock is already running.");
        assertThat(match.refuse(FINISH, at(60))).contains("The match is not over yet.");
    }

    @Test
    void whenTheTimeIsOverTheClockStopsAndOnlyFinishIsLeft() {
        add(START, null, 0);
        add(POINT, RED, 10);

        var match = replay();

        assertThat(match.remainingAt(at(500))).isZero();
        assertThat(match.isRunning(at(500))).isFalse();
        assertThat(match.endReason(at(500))).contains(EndReason.TIME);
        assertThat(match.refuse(START, at(500))).isPresent();
        assertThat(match.refuse(POINT, at(500))).isPresent();
        assertThat(match.refuse(FINISH, at(500))).isEmpty();
    }

    @Test
    void fifteenPointsEndTheMatchAndUndoingTheLastOneReopensIt() {
        add(START, null, 0);
        for (int i = 0; i < 15; i++) {
            add(POINT, BLUE, i + 1);
        }

        assertThat(replay().endReason(at(20))).contains(EndReason.POINTS);
        assertThat(replay().refuse(POINT, at(20))).isPresent();

        add(UNDO, null, 21, last());
        var match = replay();
        assertThat(match.corner(BLUE).points()).isEqualTo(14);
        assertThat(match.endReason(at(22))).isEmpty();
    }

    @Test
    void everySecondOneHandWarningGivesTheRivalAPoint() {
        add(START, null, 0);
        add(ONE_HAND_WARNING, RED, 5);
        var second = add(ONE_HAND_WARNING, RED, 10);
        add(ONE_HAND_WARNING, RED, 15);

        var match = replay();
        assertThat(match.corner(RED)).isEqualTo(new Corner(0, 0, 3));
        assertThat(match.corner(BLUE).points()).isOne();
        assertThat(match.gaveAutoPoint(second)).isTrue();

        add(UNDO, null, 20, last());
        add(UNDO, null, 21, second);
        assertThat(replay().corner(BLUE).points()).isZero();
    }

    @Test
    void disqualificationEndsTheMatchUntilUndone() {
        add(START, null, 0);
        add(WARNING, BLUE, 3);
        var dq = add(DISQUALIFICATION, BLUE, 5);
        add(STOP, null, 5);

        var match = replay();
        assertThat(match.endReason(at(6))).contains(EndReason.DISQUALIFICATION);
        assertThat(match.disqualified()).isEqualTo(BLUE);
        assertThat(match.lastUndoable()).map(Entry::id).contains(dq);

        add(UNDO, null, 7, dq);
        match = replay();
        assertThat(match.endReason(at(8))).isEmpty();
        assertThat(match.isRunning(at(8))).isFalse();
        assertThat(match.corner(BLUE).warnings()).isOne();
    }

    @Test
    void undoWalksBackOneActionAtATime() {
        add(START, null, 0);
        var first = add(POINT, RED, 1);
        var second = add(POINT, BLUE, 2);

        add(UNDO, null, 3, second);
        assertThat(replay().lastUndoable()).map(Entry::id).contains(first);
        add(UNDO, null, 4, first);
        var match = replay();
        assertThat(match.lastUndoable()).isEmpty();
        assertThat(match.refuse(UNDO, at(5))).contains("Nothing to undo.");
        assertThat(match.corner(RED).points() + match.corner(BLUE).points()).isZero();
    }

    @Test
    void aFinishedMatchRefusesEverythingButReopening() {
        add(START, null, 0);
        add(DISQUALIFICATION, RED, 1);
        add(FINISH, null, 2);

        var match = replay();
        assertThat(match.isFinished()).isTrue();
        for (var type : MatchEventType.values()) {
            if (type == MatchEventType.REOPEN) {
                assertThat(match.refuse(type, at(3))).isEmpty();
            } else {
                assertThat(match.refuse(type, at(3))).contains("The match is finished.");
            }
        }
    }

    @Test
    void nothingIsScoredBeforeTheFirstStart() {
        var match = replay();
        for (var type : List.of(POINT, WARNING, ONE_HAND_WARNING, DISQUALIFICATION)) {
            assertThat(match.refuse(type, T0)).contains(TamboMatch.NOT_STARTED);
        }
        assertThat(match.refuse(START, T0)).isEmpty();
        assertThat(match.refuse(UNDO, T0)).contains("Nothing to undo.");
        assertThat(match.refuse(FINISH, T0)).contains("The match is not over yet.");
    }

    @Test
    void aStartedAndStoppedClockStillScores() {
        add(START, null, 0);
        add(STOP, null, 10);

        var match = replay();
        for (var type : List.of(POINT, WARNING, ONE_HAND_WARNING, DISQUALIFICATION)) {
            assertThat(match.refuse(type, at(20))).isEmpty();
        }
    }

    @Test
    void aDisqualificationScoresTheLimitForTheRivalAndUndoingItGivesThePointsBack() {
        add(START, null, 0);
        add(POINT, RED, 1);
        add(POINT, RED, 2);
        add(POINT, BLUE, 3);
        var dq = add(DISQUALIFICATION, RED, 4);

        var match = replay();
        assertThat(match.corner(RED).points()).isZero();
        assertThat(match.corner(BLUE).points()).isEqualTo(15);

        add(UNDO, null, 5, dq);
        match = replay();
        assertThat(match.corner(RED).points()).isEqualTo(2);
        assertThat(match.corner(BLUE).points()).isOne();
    }

    @Test
    void aPointRemovedNeverGoesBelowZeroAndUndoGivesItBack() {
        add(START, null, 0);
        assertThat(replay().refuse(POINT_REMOVED, RED, 0, at(1))).contains("No points to take back.");
        add(POINT, RED, 1);
        add(POINT, RED, 2);
        var removed = add(POINT_REMOVED, RED, 3);

        var match = replay();
        assertThat(match.corner(RED).points()).isOne();
        assertThat(match.lastUndoable()).map(Entry::id).contains(removed);

        add(UNDO, null, 4, removed);
        assertThat(replay().corner(RED).points()).isEqualTo(2);
    }

    @Test
    void aPointCanBeTakenBackOnceTheTimeOrThePointsEndedTheMatchButNotAfterADisqualification() {
        assertThat(replay().refuse(POINT_REMOVED, RED, 0, T0)).contains(TamboMatch.NOT_STARTED);
        add(START, null, 0);
        for (int i = 0; i < 15; i++) {
            add(POINT, BLUE, i + 1);
        }
        add(STOP, null, 15);
        assertThat(replay().refuse(POINT_REMOVED, BLUE, 0, at(16))).isEmpty();
        add(POINT_REMOVED, BLUE, 16);
        assertThat(replay().endReason(at(17))).isEmpty();
        assertThat(replay().isRunning(at(17))).isFalse();

        add(START, null, 20);
        assertThat(replay().endReason(at(500))).contains(EndReason.TIME);
        assertThat(replay().refuse(POINT_REMOVED, BLUE, 0, at(500))).isEmpty();

        add(DISQUALIFICATION, RED, 21);
        assertThat(replay().refuse(POINT_REMOVED, BLUE, 0, at(500))).contains("The match is over.");
    }

    @Test
    void theStoppedClockIsAdjustedAndUndoTakesTheAdjustmentBack() {
        add(START, null, 0);
        add(STOP, null, 30);
        assertThat(replay().remainingAt(at(40))).isEqualTo(Duration.ofSeconds(90));

        var plus = adjust(10_000, 40);
        assertThat(replay().remainingAt(at(41))).isEqualTo(Duration.ofSeconds(100));
        assertThat(replay().lastUndoable()).map(Entry::id).contains(plus);
        adjust(-1_000, 41);
        assertThat(replay().remainingAt(at(42))).isEqualTo(Duration.ofSeconds(99));

        add(START, null, 50);
        assertThat(replay().remainingAt(at(60))).isEqualTo(Duration.ofSeconds(89));
        assertThat(replay().refuse(CLOCK_ADJUST, null, 1_000, at(60))).contains("Stop the clock first.");
        add(STOP, null, 60);

        add(UNDO, null, 61, entries.get(3).id());
        add(UNDO, null, 62, plus);
        assertThat(replay().remainingAt(at(63))).isEqualTo(Duration.ofSeconds(80));
    }

    @Test
    void theClockNeitherGoesBeyondTheMatchLengthNorDownToZeroByAnAdjustment() {
        var match = replay();
        assertThat(match.refuse(CLOCK_ADJUST, null, 10_000, T0)).contains("The clock cannot go further.");
        assertThat(match.refuse(CLOCK_ADJUST, null, -120_000, T0)).contains("The clock cannot go further.");
        assertThat(match.refuse(CLOCK_ADJUST, null, -10_000, T0)).isEmpty();

        add(START, null, 0);
        add(STOP, null, 5);
        adjust(10_000, 6);
        assertThat(replay().remainingAt(at(7))).isEqualTo(RULES.length());

        add(START, null, 10);
        assertThat(replay().endReason(at(500))).contains(EndReason.TIME);
        assertThat(replay().refuse(CLOCK_ADJUST, null, 10_000, at(500))).isEmpty();
        adjust(10_000, 500);
        assertThat(replay().endReason(at(501))).isEmpty();
        assertThat(replay().remainingAt(at(501))).isEqualTo(Duration.ofSeconds(10));
    }

    @Test
    void noAdjustmentAfterPointsOrADisqualificationEndedTheMatch() {
        add(START, null, 0);
        add(DISQUALIFICATION, RED, 1);
        add(STOP, null, 1);
        assertThat(replay().refuse(CLOCK_ADJUST, null, 1_000, at(2))).contains("The match is over.");
    }

    @Test
    void stopNeedsARunningClock() {
        assertThat(replay().refuse(STOP, T0)).contains("The clock is not running.");
        assertThat(replay().isStarted()).isFalse();
    }

    private UUID add(MatchEventType type, Side side, int second) {
        return add(type, side, second, null);
    }

    private UUID add(MatchEventType type, Side side, int second, UUID target) {
        var id = UUID.randomUUID();
        entries.add(new Entry(id, type, side, at(second), target));
        return id;
    }

    private UUID adjust(long deltaMs, int second) {
        var id = UUID.randomUUID();
        entries.add(new Entry(id, CLOCK_ADJUST, null, at(second), null, deltaMs));
        return id;
    }

    private UUID last() {
        return entries.getLast().id();
    }

    private TamboMatch replay() {
        return TamboMatch.replay(RULES, entries);
    }

    private static Instant at(int second) {
        return T0.plusSeconds(second);
    }
}
