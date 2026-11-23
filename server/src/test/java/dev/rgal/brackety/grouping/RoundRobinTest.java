package dev.rgal.brackety.grouping;

import static org.assertj.core.api.Assertions.assertThat;

import dev.rgal.brackety.grouping.RoundRobin.Pair;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

class RoundRobinTest {

    @Test
    void aGroupOfFourKeepsItsOrder() {
        assertThat(RoundRobin.pairs(4, false))
                .containsExactly(
                        new Pair(0, 1), new Pair(2, 3), new Pair(0, 2), new Pair(1, 3), new Pair(0, 3), new Pair(1, 2));
    }

    @Test
    void aGroupOfThreeFightsInTurns() {
        assertThat(RoundRobin.pairs(3, false)).containsExactly(new Pair(0, 1), new Pair(0, 2), new Pair(1, 2));
    }

    @ParameterizedTest
    @ValueSource(ints = {2, 3, 4, 5, 6, 7, 8})
    void everyoneFightsEveryoneOnceAndEachRoundHasEveryoneOnceAtMost(int size) {
        var pairs = RoundRobin.pairs(size, false);

        assertThat(pairs).hasSize(size * (size - 1) / 2);
        assertThat(pairs.stream().map(p -> Set.of(p.red(), p.blue())).distinct())
                .hasSameSizeAs(pairs);
        assertThat(pairs).allMatch(p -> p.red() >= 0 && p.blue() < size && p.red() != p.blue());
        var perRound = size % 2 == 0 ? size / 2 : (size - 1) / 2;
        for (int start = 0; start < pairs.size(); start += perRound) {
            var round = pairs.subList(start, start + perRound);
            var fighters = new HashSet<Integer>();
            round.forEach(p -> {
                fighters.add(p.red());
                fighters.add(p.blue());
            });
            assertThat(fighters).hasSize(perRound * 2);
        }
    }

    @ParameterizedTest
    @ValueSource(ints = {2, 3, 5, 8})
    void theReturnLegComesAfterTheWholeFirstWithTheColoursSwapped(int size) {
        var first = RoundRobin.pairs(size, false);
        var both = RoundRobin.pairs(size, true);

        assertThat(both.subList(0, first.size())).isEqualTo(first);
        assertThat(both.subList(first.size(), both.size()))
                .isEqualTo(first.stream().map(p -> new Pair(p.blue(), p.red())).toList());
        assertThat(both).hasSize(2 * first.size());
        assertThat(List.copyOf(both)).doesNotHaveDuplicates();
    }
}
