package dev.rgal.brackety.grouping;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Duration;
import org.junit.jupiter.api.Test;

class MatEstimateTest {

    private static final Duration MATCH = Duration.ofSeconds(120);
    private static final Duration CHANGEOVER = Duration.ofSeconds(30);

    @Test
    void runningMatchAddsItsClockAndEachPendingMatchAFullSlot() {
        assertThat(remaining(3, Duration.ofSeconds(45), null)).isEqualTo(Duration.ofSeconds(45 + 3 * 150));
    }

    @Test
    void rightAfterAMatchOnlyTheRestOfTheChangeoverIsOwed() {
        assertThat(remaining(2, null, Duration.ofSeconds(10))).isEqualTo(Duration.ofSeconds(20 + 120 + 150));
    }

    @Test
    void anIdleMatOwesNoChangeoverSoItsEndMovesWithTheClock() {
        assertThat(remaining(2, null, Duration.ofMinutes(5))).isEqualTo(Duration.ofSeconds(120 + 150));
        assertThat(remaining(1, null, null)).isEqualTo(MATCH);
    }

    @Test
    void anEmptyMatHasNothingLeft() {
        assertThat(remaining(0, null, Duration.ofSeconds(5))).isZero();
    }

    private static Duration remaining(int pending, Duration currentLeft, Duration sinceLastFinished) {
        return MatEstimate.remaining(pending, currentLeft, sinceLastFinished, MATCH, CHANGEOVER);
    }
}
