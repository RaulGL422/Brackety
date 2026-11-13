package dev.rgal.brackety.grouping;

import dev.rgal.brackety.grouping.MatchRecommender.Candidate;
import dev.rgal.brackety.grouping.MatchRecommender.Context;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Which match each idle mat should start now (Raul, 2026-11-13). Individual groups belong to their mat. Team
 * matches wait in one pool and go to the mats with no individual match pending: the mat idle longest picks first,
 * and nobody is proposed to two mats at once. Every pick follows {@link MatchRecommender}, so the most rested go
 * first and nobody fights without the least rest.
 */
final class MatchDispatch {

    /**
     * @param running a match is in progress on it: it gets no proposal
     * @param lastFinished when its last match finished; null if none has
     * @param justFought people of its last finished match
     * @param individual its pending individual matches that can be played (not in review)
     */
    record MatView(
            UUID matId,
            int number,
            boolean hasReferee,
            boolean running,
            Instant lastFinished,
            Set<UUID> justFought,
            List<Candidate> individual) {

        /** A mat with a referee and no individual match pending takes team matches from the pool. */
        boolean takesPool() {
            return hasReferee && individual.isEmpty();
        }
    }

    private MatchDispatch() {}

    /** Per idle mat id, the match it should start; mats with nothing to start are absent. */
    static Map<UUID, Candidate> recommend(
            List<MatView> mats, List<Candidate> pool, Context ctx, Duration individualSlot, Duration teamSlot) {
        var result = new LinkedHashMap<UUID, Candidate>();
        var proposed = new HashSet<UUID>();
        var idle = mats.stream().filter(m -> !m.running()).toList();
        for (var mat : idle.stream()
                .filter(m -> !m.individual().isEmpty())
                .sorted(Comparator.comparingInt(MatView::number))
                .toList()) {
            var context = ctx.forMat(individualSlot, mat.justFought()).alsoBusy(proposed);
            MatchRecommender.recommend(mat.individual(), context).ifPresent(pick -> {
                result.put(mat.matId(), pick);
                proposed.addAll(context.people(pick));
            });
        }
        var left = new ArrayList<>(pool);
        for (var mat : idle.stream()
                .filter(MatView::takesPool)
                .sorted(Comparator.comparing(MatView::lastFinished, Comparator.nullsFirst(Comparator.naturalOrder()))
                        .thenComparingInt(MatView::number))
                .toList()) {
            var context = ctx.forMat(teamSlot, mat.justFought()).alsoBusy(proposed);
            var pick = MatchRecommender.recommend(left, context);
            if (pick.isPresent()) {
                result.put(mat.matId(), pick.get());
                proposed.addAll(context.people(pick.get()));
                left.remove(pick.get());
            }
        }
        return result;
    }
}
