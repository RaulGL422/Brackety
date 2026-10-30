package dev.rgal.brackety.grouping;

import java.time.Duration;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.ToLongFunction;

/**
 * Picks the match a referee should run next on a mat (docs/modulos/prototipo-f1.md):
 *
 * <ol>
 *   <li>never one with a fighter who is fighting right now on any mat (a ghost can be elsewhere);
 *   <li>if possible, nobody from the match that has just finished on this mat;
 *   <li>first the matches with most fighters who have not fought yet;
 *   <li>then the most combined rest of both fighters, where sums less than one match slot apart
 *       count as equal;
 *   <li>among equals, the group that has gone longest without a match on this mat, so groups
 *       alternate; then group number and round-robin order.
 * </ol>
 */
final class MatchRecommender {

    record Candidate(UUID matchId, UUID groupId, int groupNumber, int order, UUID red, UUID blue) {}

    /**
     * @param slot one match plus the changeover: rest sums closer than this are equal
     * @param lastFought when each fighter last finished a match on any mat; absent = not fought yet
     * @param groupCreated when each group was created: the rest of a fighter who has not fought yet
     * @param groupLastPlayed when each group last finished a match on this mat; absent = never
     * @param busy fighters in a match in progress on any mat
     * @param justFought fighters of the last match finished on this mat
     */
    record Context(
            Instant now,
            Duration slot,
            Map<UUID, Instant> lastFought,
            Map<UUID, Instant> groupCreated,
            Map<UUID, Instant> groupLastPlayed,
            Set<UUID> busy,
            Set<UUID> justFought) {

        boolean isFree(Candidate c) {
            return !busy.contains(c.red()) && !busy.contains(c.blue());
        }

        int notFoughtYet(Candidate c) {
            return (lastFought.containsKey(c.red()) ? 0 : 1) + (lastFought.containsKey(c.blue()) ? 0 : 1);
        }

        long restSeconds(Candidate c) {
            return rest(c.red(), c) + rest(c.blue(), c);
        }

        private long rest(UUID fighter, Candidate c) {
            var since = lastFought.getOrDefault(fighter, groupCreated.get(c.groupId()));
            return Duration.between(since, now).toSeconds();
        }
    }

    private MatchRecommender() {}

    static Optional<UUID> recommend(List<Candidate> pending, Context ctx) {
        var options = pending.stream().filter(ctx::isFree).toList();
        var rested = options.stream()
                .filter(c ->
                        !ctx.justFought().contains(c.red()) && !ctx.justFought().contains(c.blue()))
                .toList();
        if (!rested.isEmpty()) {
            options = rested;
        }
        options = keepMax(options, ctx::notFoughtYet, 0);
        options = keepMax(options, ctx::restSeconds, ctx.slot().toSeconds() - 1);
        return options.stream()
                .min(Comparator.<Candidate, Instant>comparing(
                                c -> ctx.groupLastPlayed().get(c.groupId()),
                                Comparator.nullsFirst(Comparator.naturalOrder()))
                        .thenComparingInt(Candidate::groupNumber)
                        .thenComparingInt(Candidate::order))
                .map(Candidate::matchId);
    }

    private static List<Candidate> keepMax(List<Candidate> options, ToLongFunction<Candidate> value, long tolerance) {
        var max = options.stream().mapToLong(value).max().orElse(0);
        return options.stream()
                .filter(c -> value.applyAsLong(c) >= max - tolerance)
                .toList();
    }
}
