package dev.rgal.brackety.grouping;

import static org.assertj.core.api.Assertions.assertThat;

import dev.rgal.brackety.grouping.MatchDispatch.MatView;
import dev.rgal.brackety.grouping.MatchRecommender.Candidate;
import dev.rgal.brackety.grouping.MatchRecommender.Context;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;

/**
 * A group of four teams in the pool, nothing started, three idle mats; mat 3 has never had a match, so it picks
 * first. Mat 3 is then taken out (Raul, 2026-11-14): the match mat 2 had called must stay on mat 2.
 */
class MatchDispatchTest {

    private static final Instant NOW = Instant.parse("2026-11-14T11:00:00Z");
    private static final Duration SLOT = Duration.ofSeconds(210);

    private final UUID group = UUID.randomUUID();
    private final List<UUID> teams =
            List.of(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID());
    private final List<Candidate> pool = new ArrayList<>();
    private final MatView mat1 = mat(1, NOW.minusSeconds(600));
    private final MatView mat2 = mat(2, NOW.minusSeconds(1200));
    private final MatView mat3 = mat(3, null);

    MatchDispatchTest() {
        int[][] pairs = {{0, 1}, {2, 3}, {0, 2}, {1, 3}, {0, 3}, {1, 2}};
        for (int i = 0; i < pairs.length; i++) {
            pool.add(new Candidate(UUID.randomUUID(), group, 1, i, teams.get(pairs[i][0]), teams.get(pairs[i][1])));
        }
    }

    @Test
    void aMatTakenOutLeavesTheOthersWithTheMatchesTheyHad() {
        var before = recommend(List.of(mat1, mat2, mat3), Map.of());
        assertThat(before).containsOnlyKeys(mat3.matId(), mat2.matId());
        var mat2Had = before.get(mat2.matId()).matchId();
        var kept = before.entrySet().stream()
                .collect(Collectors.toMap(Map.Entry::getKey, e -> e.getValue().matchId()));

        var after = recommend(List.of(mat1, mat2), kept);

        assertThat(after.get(mat2.matId()).matchId()).isEqualTo(mat2Had);
        // Mat 1 gets the one mat 3 had.
        assertThat(after.get(mat1.matId()).matchId())
                .isEqualTo(before.get(mat3.matId()).matchId());
        // Dealt afresh, mat 2 (idle longest) would have taken mat 3's and moved its own to mat 1.
        assertThat(recommend(List.of(mat1, mat2), Map.of()).get(mat2.matId()).matchId())
                .isNotEqualTo(mat2Had);
    }

    @Test
    void aKeptMatchThatCannotStartAnyMoreIsDealtAgain() {
        var kept = Map.of(mat2.matId(), pool.getFirst().matchId());
        var busy = Set.of(teams.get(0));

        var picks = MatchDispatch.recommend(List.of(mat1, mat2), pool, context(busy), SLOT, SLOT, kept);

        assertThat(picks.values())
                .extracting(Candidate::matchId)
                .doesNotContain(pool.getFirst().matchId());
        assertThat(picks).containsKey(mat2.matId());
    }

    private Map<UUID, Candidate> recommend(List<MatView> mats, Map<UUID, UUID> kept) {
        return MatchDispatch.recommend(mats, pool, context(Set.of()), SLOT, SLOT, kept);
    }

    private Context context(Set<UUID> busy) {
        return new Context(
                NOW,
                SLOT,
                new HashMap<>(),
                Map.of(group, NOW.minusSeconds(3600)),
                new HashMap<>(),
                busy,
                Set.of(),
                Map.of(),
                Duration.ofSeconds(30));
    }

    private static MatView mat(int number, Instant lastFinished) {
        return new MatView(UUID.randomUUID(), number, true, false, lastFinished, Set.of(), List.of());
    }
}
