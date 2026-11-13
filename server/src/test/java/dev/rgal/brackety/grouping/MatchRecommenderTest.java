package dev.rgal.brackety.grouping;

import static org.assertj.core.api.Assertions.assertThat;

import dev.rgal.brackety.grouping.MatchRecommender.Candidate;
import dev.rgal.brackety.grouping.MatchRecommender.Context;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class MatchRecommenderTest {

    private static final Instant START = Instant.parse("2027-03-10T09:00:00Z");
    private static final Duration MATCH = Duration.ofSeconds(120);
    private static final Duration CHANGEOVER = Duration.ofSeconds(30);

    @Test
    void oneGroupFollowsTheRoundRobinWithoutBackToBackFights() {
        var mat = new SimulatedMat();
        var group = mat.addGroup(1);

        assertThat(mat.playAll())
                .containsExactly(
                        group.match(1, 2),
                        group.match(3, 4),
                        group.match(1, 3),
                        group.match(2, 4),
                        group.match(1, 4),
                        group.match(2, 3));
    }

    @Test
    void twoGroupsCreatedTogetherAlternateWhileNobodyHasFought() {
        var mat = new SimulatedMat();
        var first = mat.addGroup(1);
        var second = mat.addGroup(2);

        var played = mat.playAll();

        assertThat(played.subList(0, 4))
                .containsExactly(first.match(1, 2), second.match(1, 2), first.match(3, 4), second.match(3, 4));
        assertThat(played).hasSize(12).doesNotHaveDuplicates();
        for (int i = 1; i < played.size(); i++) {
            assertThat(mat.fighters(played.get(i))).doesNotContainAnyElementsOf(mat.fighters(played.get(i - 1)));
        }
    }

    @Test
    void neverRecommendsAFighterWhoIsFightingOnAnotherMat() {
        var mat = new SimulatedMat();
        var group = mat.addGroup(1);
        mat.busy.add(group.fighters().get(0));

        assertThat(mat.recommend()).contains(group.match(3, 4));

        mat.busy.addAll(group.fighters());
        assertThat(mat.recommend()).isEmpty();
    }

    @Test
    void restSumsWithinOneSlotCountAsEqualSoTheGroupWaitingLongestGoes() {
        var mat = matWithOneMatchPerGroup(100);

        assertThat(mat.recommend()).contains(mat.second.match(1, 2));
    }

    @Test
    void aRestSumOneSlotLongerWinsOverAlternatingGroups() {
        var mat = matWithOneMatchPerGroup(150);

        assertThat(mat.recommend()).contains(mat.first.match(1, 2));
    }

    /** Group 1's pair rested {@code extraRest} seconds more in total, but group 2 waited longer for the mat. */
    private static SimulatedMat matWithOneMatchPerGroup(int extraRest) {
        var mat = new SimulatedMat();
        mat.first = mat.addGroup(1);
        mat.second = mat.addGroup(2);
        mat.pending.removeIf(
                c -> !c.matchId().equals(mat.first.match(1, 2)) && !c.matchId().equals(mat.second.match(1, 2)));
        mat.now = START.plusSeconds(1000);
        for (int i = 0; i < 2; i++) {
            mat.lastFought.put(mat.first.fighters().get(i), START.plusSeconds(500));
            mat.lastFought.put(mat.second.fighters().get(i), START.plusSeconds(500 + extraRest / 2));
        }
        mat.groupLastPlayed.put(mat.first.id(), START.plusSeconds(500));
        mat.groupLastPlayed.put(mat.second.id(), START.plusSeconds(200));
        return mat;
    }

    @Test
    void nothingPendingMeansNoRecommendation() {
        assertThat(new SimulatedMat().recommend()).isEmpty();
    }

    /** A mat where every recommended match is played at once: 2 min of fight and 30 s of changeover. */
    private static class SimulatedMat {

        Instant now = START;
        final List<Candidate> pending = new ArrayList<>();
        final Map<UUID, Instant> lastFought = new HashMap<>();
        final Map<UUID, Instant> groupCreated = new HashMap<>();
        final Map<UUID, Instant> groupLastPlayed = new HashMap<>();
        final Set<UUID> busy = new HashSet<>();
        Set<UUID> justFought = Set.of();
        Group first;
        Group second;
        final Map<UUID, Candidate> byId = new HashMap<>();

        Group addGroup(int number) {
            var group = new Group(UUID.randomUUID(), List.of(id(), id(), id(), id()));
            groupCreated.put(group.id, now);
            var pairs = RoundRobin.pairs();
            for (int i = 0; i < pairs.size(); i++) {
                var pair = pairs.get(i);
                var candidate = new Candidate(
                        UUID.randomUUID(),
                        group.id,
                        number,
                        i,
                        group.fighters.get(pair.red()),
                        group.fighters.get(pair.blue()));
                pending.add(candidate);
                byId.put(candidate.matchId(), candidate);
                group.matches.put(pair.red() * 10 + pair.blue(), candidate.matchId());
            }
            return group;
        }

        Optional<UUID> recommend() {
            return MatchRecommender.recommend(
                            pending,
                            new Context(
                                    now,
                                    MATCH.plus(CHANGEOVER),
                                    lastFought,
                                    groupCreated,
                                    groupLastPlayed,
                                    busy,
                                    justFought,
                                    Map.of(),
                                    Duration.ZERO))
                    .map(Candidate::matchId);
        }

        void play(UUID matchId) {
            var match = byId.get(matchId);
            pending.remove(match);
            now = now.plus(MATCH);
            lastFought.put(match.red(), now);
            lastFought.put(match.blue(), now);
            groupLastPlayed.put(match.groupId(), now);
            justFought = Set.of(match.red(), match.blue());
            now = now.plus(CHANGEOVER);
        }

        List<UUID> playAll() {
            return playAll(Integer.MAX_VALUE);
        }

        List<UUID> playAll(int limit) {
            var played = new ArrayList<UUID>();
            while (played.size() < limit) {
                var next = recommend();
                if (next.isEmpty()) {
                    break;
                }
                play(next.get());
                played.add(next.get());
            }
            return played;
        }

        Set<UUID> fighters(UUID matchId) {
            var match = byId.get(matchId);
            return Set.of(match.red(), match.blue());
        }

        private static UUID id() {
            return UUID.randomUUID();
        }
    }

    private record Group(UUID id, List<UUID> fighters, Map<Integer, UUID> matches) {

        Group(UUID id, List<UUID> fighters) {
            this(id, fighters, new HashMap<>());
        }

        /** Match between fighters at positions {@code a} and {@code b}, counting from 1. */
        UUID match(int a, int b) {
            return matches.get((a - 1) * 10 + (b - 1));
        }
    }
}
