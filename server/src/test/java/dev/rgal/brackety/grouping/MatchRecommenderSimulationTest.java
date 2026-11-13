package dev.rgal.brackety.grouping;

import static org.assertj.core.api.Assertions.assertThat;

import dev.rgal.brackety.grouping.MatchRecommender.Candidate;
import dev.rgal.brackety.grouping.MatchRecommender.Context;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Random;
import java.util.Set;
import java.util.UUID;
import java.util.function.Supplier;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * A whole event played with the recommender: several mats, groups of participants or teams, ghosts who are
 * real in another group, groups created while others fight and matches of random length. Every mat always
 * runs its recommended match, as the referee would.
 */
class MatchRecommenderSimulationTest {

    private static final Instant START = Instant.parse("2027-03-10T09:00:00Z");
    private static final Duration MATCH = Duration.ofSeconds(180);
    private static final Duration CHANGEOVER = Duration.ofSeconds(30);

    @Test
    void threeGroupsCreatedTogetherTakeTurnsUntilEveryoneHasFought() {
        var event = new SimulatedEvent(new Random(1));
        var mat = event.addMat();
        var groups = List.of(
                event.addGroup(mat, 1, false, START),
                event.addGroup(mat, 2, false, START),
                event.addGroup(mat, 3, false, START));

        event.playAll(fixed());

        assertThat(mat.played.subList(0, 6))
                .containsExactly(
                        groups.get(0).match(1, 2),
                        groups.get(1).match(1, 2),
                        groups.get(2).match(1, 2),
                        groups.get(0).match(3, 4),
                        groups.get(1).match(3, 4),
                        groups.get(2).match(3, 4));
        event.assertAllPlayedOnce();
        assertThat(mat.backToBack).isZero();
        // Then the most rested fighters go first: a group may wait while two others fight twice each.
        assertThat(mat.longestWait()).as(event.log.toString()).isLessThanOrEqualTo(4);
    }

    @Test
    void aGroupCreatedMidwayFightsFirstUntilAllItsFightersHaveFought() {
        var event = new SimulatedEvent(new Random(2));
        var mat = event.addMat();
        var first = event.addGroup(mat, 1, false, START);
        var second =
                event.addGroup(mat, 2, false, START.plus(slot().multipliedBy(3)).minusSeconds(1));

        event.playAll(fixed());

        assertThat(mat.played.subList(0, 5))
                .as(event.log.toString())
                .containsExactly(
                        first.match(1, 2),
                        first.match(3, 4),
                        first.match(1, 3),
                        second.match(1, 2),
                        second.match(3, 4));
        event.assertAllPlayedOnce();
        assertThat(mat.backToBack).isZero();
    }

    @Test
    void teamGroupsAlternateAndATeamWaitsWhileOneOfItsMembersFightsElsewhere() {
        var event = new SimulatedEvent(new Random(3));
        var mat = event.addMat();
        var other = event.addMat();
        var first = event.addGroup(mat, 1, true, START);
        var second = event.addGroup(mat, 2, true, START);
        // The ghost team of mat 2 borrows two members of group 1's first team.
        var borrowed =
                event.teamMembers.get(first.fighters().get(0)).stream().limit(2).collect(Collectors.toSet());
        event.addGroupWithGhost(other, 3, true, START, borrowed);

        event.playAll(fixed());

        assertThat(mat.played.subList(0, 2)).containsExactly(first.match(1, 2), second.match(1, 2));
        event.assertAllPlayedOnce();
        assertThat(mat.backToBack).isZero();
        assertThat(other.backToBack).isZero();
    }

    @Test
    void aGhostFightingOnAnotherMatHoldsBackOnlyTheMatchesWithThem() {
        var event = new SimulatedEvent(new Random(4));
        var mat = event.addMat();
        var other = event.addMat();
        var real = event.addGroup(other, 1, false, START);
        event.addGroupWithGhost(mat, 2, false, START, Set.of(real.fighters().get(0)));
        event.busy.add(real.fighters().get(0));

        var recommended = event.recommend(mat);

        assertThat(recommended).isPresent();
        assertThat(event.people(recommended.get()))
                .doesNotContain(real.fighters().get(0));

        event.busy.clear();
        event.playAll(fixed());
        event.assertAllPlayedOnce();
    }

    /** Many random events, each from its own seed so a failure can be replayed. */
    @ParameterizedTest
    @ValueSource(ints = {1, 2, 3, 4})
    void randomEventsNeverDoubleBookAFighterNorStarveAGroupNorLeaveAMatchUnplayed(int mats) {
        for (int seed = 0; seed < 400; seed++) {
            var random = new Random(seed * 31L + mats);
            var event = SimulatedEvent.random(random, mats);

            event.playAll(() -> Duration.ofSeconds(20 + random.nextInt(161)));

            event.assertAllPlayedOnce();
            for (var mat : event.mats) {
                assertThat(mat.backToBack)
                        .as("seed %d: back-to-back with an alternative", seed)
                        .isZero();
                assertThat(mat.longestWait())
                        .as("seed %d: a group waited too long with a match it could fight", seed)
                        .isLessThanOrEqualTo(2 * (mat.groups.size() - 1) + 1);
            }
        }
    }

    private static Duration slot() {
        return MATCH.plus(CHANGEOVER);
    }

    private static Supplier<Duration> fixed() {
        return () -> MATCH;
    }

    /** Fighters are participant ids or team ids ({@link #teamMembers}). */
    private static final class SimulatedEvent {

        final Random random;
        final List<SimMat> mats = new ArrayList<>();
        final Map<UUID, Set<UUID>> teamMembers = new HashMap<>();
        final Map<UUID, Instant> lastFought = new HashMap<>();
        final Map<UUID, Instant> groupCreated = new HashMap<>();
        final Map<UUID, Candidate> byId = new HashMap<>();
        final Set<UUID> busy = new HashSet<>();
        final List<UUID> playedAll = new ArrayList<>();
        Instant now = START;
        final StringBuilder log = new StringBuilder();

        SimulatedEvent(Random random) {
            this.random = random;
        }

        /** 1 to 3 groups per mat, a third of them by teams, some with a ghost, created over the first hour. */
        static SimulatedEvent random(Random random, int matCount) {
            var event = new SimulatedEvent(random);
            var number = 0;
            var created = new ArrayList<SimGroup>();
            for (int m = 0; m < matCount; m++) {
                var mat = event.addMat();
                var groupCount = 1 + random.nextInt(3);
                for (int g = 0; g < groupCount; g++) {
                    var teams = random.nextInt(3) == 0;
                    var at = random.nextInt(3) == 0 ? START : START.plusSeconds(random.nextInt(3600));
                    var donors =
                            created.stream().filter(c -> c.teams() == teams).toList();
                    if (!donors.isEmpty() && random.nextInt(3) == 0) {
                        var donor = donors.get(random.nextInt(donors.size()));
                        var ghostPeople = teams
                                ? Set.copyOf(
                                        event.teamMembers.get(donor.fighters().get(random.nextInt(4))))
                                : Set.of(donor.fighters().get(random.nextInt(4)));
                        created.add(event.addGroupWithGhost(mat, ++number, teams, at, ghostPeople));
                    } else {
                        created.add(event.addGroup(mat, ++number, teams, at));
                    }
                }
            }
            return event;
        }

        SimMat addMat() {
            var mat = new SimMat();
            mats.add(mat);
            return mat;
        }

        SimGroup addGroup(SimMat mat, int number, boolean teams, Instant at) {
            var fighters = new ArrayList<UUID>();
            for (int i = 0; i < 4; i++) {
                fighters.add(newFighter(teams));
            }
            return add(mat, number, teams, fighters, at);
        }

        /** Three real fighters and a ghost made of {@code ghostPeople}, who are real somewhere else. */
        SimGroup addGroupWithGhost(SimMat mat, int number, boolean teams, Instant at, Set<UUID> ghostPeople) {
            var fighters = new ArrayList<UUID>();
            for (int i = 0; i < 3; i++) {
                fighters.add(newFighter(teams));
            }
            if (teams) {
                var ghost = UUID.randomUUID();
                teamMembers.put(ghost, ghostPeople);
                fighters.add(ghost);
            } else {
                fighters.add(ghostPeople.iterator().next());
            }
            return add(mat, number, teams, fighters, at);
        }

        private UUID newFighter(boolean team) {
            var id = UUID.randomUUID();
            if (team) {
                teamMembers.put(id, Set.of(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID()));
            }
            return id;
        }

        private SimGroup add(SimMat mat, int number, boolean teams, List<UUID> fighters, Instant at) {
            var group = new SimGroup(UUID.randomUUID(), number, teams, fighters, new HashMap<>());
            var pairs = RoundRobin.pairs();
            var matches = new ArrayList<Candidate>();
            for (int i = 0; i < pairs.size(); i++) {
                var pair = pairs.get(i);
                var candidate = new Candidate(
                        UUID.randomUUID(), group.id(), number, i, fighters.get(pair.red()), fighters.get(pair.blue()));
                matches.add(candidate);
                byId.put(candidate.matchId(), candidate);
                group.matches().put(pair.red() * 10 + pair.blue(), candidate.matchId());
            }
            mat.scheduled.put(group, new Scheduled(at, matches));
            mat.groups.add(group);
            return group;
        }

        Set<UUID> people(UUID matchId) {
            var match = byId.get(matchId);
            var result = new HashSet<>(teamMembers.getOrDefault(match.red(), Set.of(match.red())));
            result.addAll(teamMembers.getOrDefault(match.blue(), Set.of(match.blue())));
            return result;
        }

        Optional<UUID> recommend(SimMat mat) {
            mat.release(now, groupCreated);
            return MatchRecommender.recommend(
                            mat.pending,
                            new Context(
                                    now,
                                    slot(),
                                    lastFought,
                                    groupCreated,
                                    mat.groupLastPlayed,
                                    busy,
                                    mat.justFought,
                                    teamMembers,
                                    Duration.ZERO))
                    .map(Candidate::matchId);
        }

        /** Each free mat starts its recommended match; time jumps to the next end or new group. */
        void playAll(Supplier<Duration> length) {
            for (int step = 0; step < 10_000; step++) {
                for (var mat : mats) {
                    if (mat.running == null && !now.isBefore(mat.freeFrom)) {
                        start(mat, length);
                    }
                }
                var next =
                        mats.stream().flatMap(m -> m.nextMoments(now).stream()).min(Comparator.naturalOrder());
                if (next.isEmpty()) {
                    assertThat(mats).allMatch(m -> m.pending.isEmpty() && m.scheduled.isEmpty());
                    return;
                }
                now = next.get();
                for (var mat : mats) {
                    if (mat.running != null && !now.isBefore(mat.endsAt)) {
                        finish(mat);
                    }
                }
            }
            throw new AssertionError("the event never ended");
        }

        private void start(SimMat mat, Supplier<Duration> length) {
            var recommended = recommend(mat);
            var free = mat.pending.stream()
                    .filter(c -> people(c.matchId()).stream().noneMatch(busy::contains))
                    .toList();
            if (recommended.isEmpty()) {
                assertThat(free)
                        .as("a mat stood idle with a match it could start")
                        .isEmpty();
                return;
            }
            var match = byId.get(recommended.get());
            log.append(now + " g" + match.groupNumber() + " o" + match.order() + " p=" + mat.pending.size() + "; ");
            assertThat(mat.pending).contains(match);
            var fighters = people(match.matchId());
            assertThat(fighters).as("a fighter in two matches at once").noneMatch(busy::contains);
            if (fighters.stream().anyMatch(mat.justFought::contains)
                    && free.stream().anyMatch(c -> people(c.matchId()).stream().noneMatch(mat.justFought::contains))) {
                mat.backToBack++;
            }
            mat.countWaits(match, free, this);
            mat.pending.remove(match);
            busy.addAll(fighters);
            mat.running = match;
            mat.endsAt = now.plus(length.get());
        }

        private void finish(SimMat mat) {
            var match = mat.running;
            var fighters = people(match.matchId());
            busy.removeAll(fighters);
            fighters.forEach(p -> lastFought.put(p, now));
            mat.groupLastPlayed.put(match.groupId(), now);
            mat.justFought = fighters;
            mat.played.add(match.matchId());
            playedAll.add(match.matchId());
            mat.running = null;
            mat.freeFrom = now.plus(CHANGEOVER);
        }

        void assertAllPlayedOnce() {
            assertThat(playedAll).doesNotHaveDuplicates().containsExactlyInAnyOrderElementsOf(byId.keySet());
        }
    }

    private record Scheduled(Instant at, List<Candidate> matches) {}

    private static final class SimMat {

        final List<SimGroup> groups = new ArrayList<>();
        final Map<SimGroup, Scheduled> scheduled = new LinkedHashMap<>();
        final List<Candidate> pending = new ArrayList<>();
        final Map<UUID, Instant> groupLastPlayed = new HashMap<>();
        final List<UUID> played = new ArrayList<>();
        final Map<UUID, Integer> waits = new HashMap<>();
        int maxWait;
        Set<UUID> justFought = Set.of();
        Candidate running;
        Instant endsAt;
        Instant freeFrom = START;
        int backToBack;

        /** Groups whose creation time has come join the mat's pending matches. */
        void release(Instant now, Map<UUID, Instant> groupCreated) {
            var it = scheduled.entrySet().iterator();
            while (it.hasNext()) {
                var entry = it.next();
                if (!entry.getValue().at().isAfter(now)) {
                    groupCreated.put(entry.getKey().id(), entry.getValue().at());
                    pending.addAll(entry.getValue().matches());
                    it.remove();
                }
            }
        }

        List<Instant> nextMoments(Instant now) {
            var moments = new ArrayList<Instant>();
            if (running != null) {
                moments.add(endsAt);
            } else if (freeFrom.isAfter(now)) {
                moments.add(freeFrom);
            }
            scheduled.values().stream()
                    .map(Scheduled::at)
                    .filter(at -> at.isAfter(now))
                    .forEach(moments::add);
            return moments;
        }

        // How many matches of other groups a group with a match it could fight (free, nobody just fought) saw go first.
        void countWaits(Candidate chosen, List<Candidate> free, SimulatedEvent event) {
            var ready = free.stream()
                    .filter(c -> event.people(c.matchId()).stream().noneMatch(justFought::contains))
                    .map(Candidate::groupId)
                    .collect(Collectors.toSet());
            for (var group : ready) {
                if (group.equals(chosen.groupId())) {
                    waits.put(group, 0);
                } else {
                    var wait = waits.merge(group, 1, Integer::sum);
                    maxWait = Math.max(maxWait, wait);
                }
            }
            waits.put(chosen.groupId(), 0);
        }

        int longestWait() {
            return maxWait;
        }
    }

    private record SimGroup(UUID id, int number, boolean teams, List<UUID> fighters, Map<Integer, UUID> matches) {

        /** Match between fighters at positions {@code a} and {@code b}, counting from 1. */
        UUID match(int a, int b) {
            return matches.get((a - 1) * 10 + (b - 1));
        }
    }
}
