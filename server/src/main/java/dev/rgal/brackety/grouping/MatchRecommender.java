package dev.rgal.brackety.grouping;

import java.time.Duration;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Predicate;
import java.util.function.ToLongFunction;

/**
 * Picks the match a referee should run next on a mat (docs/modulos/prototipo-f1.md):
 *
 * <ol>
 *   <li>never one with a fighter who is fighting right now on any mat (a ghost can be elsewhere);
 *       a team is busy when any of its members is;
 *   <li>if possible, nobody from the match that has just finished on this mat;
 *   <li>first the matches with most fighters who have not fought yet;
 *   <li>then the most combined rest of both fighters, where sums less than one match slot apart
 *       count as equal; a team rests as little as its least rested member;
 *   <li>among equals, the group that has gone longest without a match on this mat, so groups
 *       alternate; then group number and round-robin order.
 * </ol>
 */
final class MatchRecommender {

    /** {@code red} and {@code blue}: a participant's or a team's id. */
    record Candidate(UUID matchId, UUID groupId, int groupNumber, int order, UUID red, UUID blue) {}

    /**
     * @param slot one match plus the changeover: rest sums closer than this are equal
     * @param lastFought when each fighter last finished a match on any mat; absent = not fought yet
     * @param groupCreated when each group was created: the rest of a fighter who has not fought yet
     * @param groupLastPlayed when each group last finished a match on this mat; absent = never
     * @param busy fighters in a match in progress on any mat
     * @param justFought fighters of the last match finished on this mat
     * @param teamMembers the members of each team; every other id is a single participant
     */
    record Context(
            Instant now,
            Duration slot,
            Map<UUID, Instant> lastFought,
            Map<UUID, Instant> groupCreated,
            Map<UUID, Instant> groupLastPlayed,
            Set<UUID> busy,
            Set<UUID> justFought,
            Map<UUID, Set<UUID>> teamMembers) {

        boolean isFree(Candidate c) {
            return none(c, busy::contains);
        }

        boolean isRested(Candidate c) {
            return none(c, justFought::contains);
        }

        int notFoughtYet(Candidate c) {
            return notFought(c.red()) + notFought(c.blue());
        }

        long restSeconds(Candidate c) {
            return rest(c.red(), c) + rest(c.blue(), c);
        }

        private Set<UUID> people(UUID fighter) {
            return teamMembers.getOrDefault(fighter, Set.of(fighter));
        }

        private boolean none(Candidate c, Predicate<UUID> test) {
            return people(c.red()).stream().noneMatch(test)
                    && people(c.blue()).stream().noneMatch(test);
        }

        private int notFought(UUID fighter) {
            return people(fighter).stream().anyMatch(lastFought::containsKey) ? 0 : 1;
        }

        private long rest(UUID fighter, Candidate c) {
            return people(fighter).stream()
                    .mapToLong(p -> Duration.between(lastFought.getOrDefault(p, groupCreated.get(c.groupId())), now)
                            .toSeconds())
                    .min()
                    .orElseThrow();
        }
    }

    private MatchRecommender() {}

    static Optional<UUID> recommend(List<Candidate> pending, Context ctx) {
        var options = pending.stream().filter(ctx::isFree).toList();
        var rested = options.stream().filter(ctx::isRested).toList();
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
