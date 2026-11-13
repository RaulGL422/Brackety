package dev.rgal.brackety.scoreboard;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class OneHandAgeTest {

    @Test
    void fromFourToEightTheyFightWithBothHands() {
        assertThat(MatchWriter.oneHandAge(3)).isFalse();
        assertThat(MatchWriter.oneHandAge(4)).isTrue();
        assertThat(MatchWriter.oneHandAge(8)).isTrue();
        assertThat(MatchWriter.oneHandAge(9)).isFalse();
    }
}
