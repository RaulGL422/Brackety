package dev.rgal.brackety.ranking;

import static org.assertj.core.api.Assertions.assertThat;

import dev.rgal.brackety.event.TestSports;
import dev.rgal.brackety.scoreboard.Side;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** The FELODA order of a group (art. 8 and 39) on fixed results. */
class ClassificationStandingsTest {

    private final UUID ana = UUID.randomUUID();
    private final UUID bea = UUID.randomUUID();
    private final UUID carla = UUID.randomUUID();

    private final ClassificationStandings standings = new ClassificationStandings(TestSports.GRAPPLING);

    @Test
    void eachWayOfWinningGivesItsPoints() {
        standings.add(Side.RED, "SUBMISSION", 2, 0, Set.of(ana), Set.of(bea));
        standings.add(Side.RED, "SUPERIORITY", 17, 2, Set.of(ana), Set.of(carla));
        standings.add(Side.BLUE, "TIME", 0, 3, Set.of(bea), Set.of(carla));

        assertThat(standings.tally(ana).points).isEqualTo(5 + 4);
        assertThat(standings.tally(ana).wins).isEqualTo(2);
        // Lost on superiority having scored (1) and won on decision against someone who did not (3).
        assertThat(standings.tally(carla).points).isEqualTo(1 + 3);
        assertThat(standings.tally(bea).points).isZero();
        assertThat(standings.tally(ana).submissions).isOne();
        assertThat(standings.tally(ana).superiorities).isOne();
        assertThat(standings.tally(ana).technical).isEqualTo(19);
    }

    // Two with the same record: the match between them decides.
    @Test
    void twoTiedGoByTheMatchBetweenThem() {
        standings.add(Side.BLUE, "TIME", 2, 4, Set.of(ana), Set.of(bea));
        standings.add(Side.RED, "TIME", 4, 2, Set.of(ana), Set.of(carla));
        standings.add(Side.RED, "TIME", 3, 2, Set.of(carla), Set.of(bea));
        // Ana and Bea: 1 win, 4 classification points (3 + 1) and 6 technical points each; Bea beat Ana.

        var ranked = standings.rank(List.of(ana, bea), id -> id);

        assertThat(ranked).extracting(ClassificationStandings.Placed::item).containsExactly(bea, ana);
        assertThat(ranked).extracting(ClassificationStandings.Placed::position).containsExactly(1, 2);
    }

    // GR-5: with a return leg each won once; the points they scored against each other decide.
    @Test
    void twoTiedAfterBothLegsGoByThePointsScoredBetweenThem() {
        standings.add(Side.RED, "TIME", 2, 1, Set.of(ana), Set.of(bea));
        standings.add(Side.RED, "TIME", 3, 1, Set.of(bea), Set.of(ana));
        standings.add(Side.RED, "TIME", 4, 2, Set.of(carla), Set.of(ana));
        standings.add(Side.RED, "TIME", 4, 1, Set.of(carla), Set.of(bea));
        // Ana and Bea: 1 win, 5 classification points and 5 technical each. Between them: Ana 3, Bea 4.

        var ranked = standings.rank(List.of(ana, bea), id -> id);

        assertThat(ranked).extracting(ClassificationStandings.Placed::item).containsExactly(bea, ana);
        assertThat(ranked).extracting(ClassificationStandings.Placed::position).containsExactly(1, 2);
    }

    @Test
    void anEqualRecordWithoutAMatchBetweenThemSharesThePosition() {
        standings.add(Side.RED, "SUBMISSION", 0, 0, Set.of(ana), Set.of(carla));
        standings.add(Side.RED, "SUBMISSION", 0, 0, Set.of(bea), Set.of(carla));

        var ranked = standings.rank(List.of(carla, ana, bea), id -> id);

        assertThat(ranked).extracting(ClassificationStandings.Placed::position).containsExactly(1, 1, 3);
        assertThat(ranked.getLast().item()).isEqualTo(carla);
    }
}
