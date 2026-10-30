package dev.rgal.brackety.scoreboard;

import static dev.rgal.brackety.scoreboard.MatchEventType.DISQUALIFICATION;
import static dev.rgal.brackety.scoreboard.MatchEventType.FINISH;
import static dev.rgal.brackety.scoreboard.MatchEventType.ONE_HAND_WARNING;
import static dev.rgal.brackety.scoreboard.MatchEventType.POINT;
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
    void aFinishedMatchRefusesEverything() {
        add(START, null, 0);
        add(DISQUALIFICATION, RED, 1);
        add(FINISH, null, 2);

        var match = replay();
        assertThat(match.isFinished()).isTrue();
        for (var type : MatchEventType.values()) {
            assertThat(match.refuse(type, at(3))).contains("The match is finished.");
        }
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
