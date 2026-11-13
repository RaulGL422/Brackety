package dev.rgal.brackety.grouping;

import static org.assertj.core.api.Assertions.assertThat;

import dev.rgal.brackety.grouping.MatchDispatch.MatView;
import dev.rgal.brackety.grouping.MatchRecommender.Candidate;
import dev.rgal.brackety.grouping.MatchRecommender.Context;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.stream.LongStream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * A whole day on 3 mats with {@link MatchDispatch} (Raul, 2026-11-13): individual groups with wildcards who are real
 * in another group or in a team, team groups of teams of 2 and 3 (with wildcard teams) whose matches go to the mats
 * free of individual matches, and the least rest between two matches of a person. Matches end at random (points or
 * time) and each idle mat starts its proposal, as the referees would.
 */
class MatchDispatchSimulationTest {

    private static final Instant START = Instant.parse("2026-11-14T09:00:00Z");
    private static final Duration INDIVIDUAL = Duration.ofSeconds(60);
    private static final Duration TEAM = Duration.ofSeconds(180);
    private static final Duration CHANGEOVER = Duration.ofSeconds(30);
    private static final Duration MIN_REST = Duration.ofSeconds(30);

    static LongStream typicalSeeds() {
        return LongStream.rangeClosed(1, 60);
    }

    static LongStream tangledSeeds() {
        return LongStream.rangeClosed(1001, 1060);
    }

    @ParameterizedTest
    @MethodSource("typicalSeeds")
    void aFullDayEndsWithEveryMatchPlayedOnceAndEveryoneRested(long seed) {
        var day = new Day(new Random(seed), 3);
        day.typicalPhase();

        day.playAll();

        day.assertEveryMatchPlayedOnce();
        day.assertNobodyInTwoMatchesAtOnce();
        day.assertEveryoneRested();
        day.assertTeamMatchesOnlyOnMatsFreeOfIndividualMatches();
    }

    @ParameterizedTest
    @ValueSource(longs = {21, 22, 23, 24, 25})
    void teamMatchesAreSpreadOverTheFreeMats(long seed) {
        var day = new Day(new Random(seed), 3);
        for (int g = 0; g < 4; g++) {
            day.teamGroup(List.of(3, 3, 2, 3), 0, START);
        }

        day.playAll();

        day.assertEveryMatchPlayedOnce();
        day.assertEveryoneRested();
        var perMat = day.teamMatchesPerMat();
        assertThat(perMat.values()).as(perMat.toString()).allMatch(n -> n >= 5);
    }

    /**
     * Wildcards taken from anyone already in the day (Raul, 2026-11-13): someone real in a team can fill an
     * individual group and a wildcard team of other groups, all at once. On 1 to 3 mats.
     */
    @ParameterizedTest
    @MethodSource("tangledSeeds")
    void wildcardsTangledEverywhereNeverDoubleBookAnyoneAndEveryoneRests(long seed) {
        var day = new Day(new Random(seed), 1 + (int) (seed % 3));
        day.tangledPhase();

        day.playAll();

        day.assertEveryMatchPlayedOnce();
        day.assertNobodyInTwoMatchesAtOnce();
        day.assertEveryoneRested();
        day.assertTeamMatchesOnlyOnMatsFreeOfIndividualMatches();
        assertThat(day.peopleInSeveralGroups()).as("the day was really tangled").isPositive();
    }

    @Test
    void aTeamWhoseMemberFightsAloneWaitsForThemAndTheirRest() {
        var day = new Day(new Random(31), 2);
        var shared = day.person();
        // The shared person is real in an individual group on mat 1 and in team 1 of the pool.
        day.individualGroup(0, List.of(shared), 0, START);
        var teamGroup = day.teamGroup(List.of(2, 2, 2, 2), 0, START);
        day.addToFirstTeam(teamGroup, shared);

        day.playAll();

        day.assertEveryMatchPlayedOnce();
        day.assertNobodyInTwoMatchesAtOnce();
        day.assertEveryoneRested();
    }

    @Test
    void aGroupOfOneTeamAndThreeWildcardTeamsIsPlayed() {
        var day = new Day(new Random(41), 3);
        day.teamGroup(List.of(3), 3, START);
        day.individualGroup(0, List.of(), 0, START);

        day.playAll();

        day.assertEveryMatchPlayedOnce();
        day.assertEveryoneRested();
    }

    @Test
    void theMostRestedTeamsGoFirst() {
        var day = new Day(new Random(51), 1);
        day.teamGroup(List.of(3, 3, 3, 3), 0, START);
        day.teamGroup(List.of(3, 3, 3, 3), 0, START.plusSeconds(1));

        day.playAll();

        // Groups alternate: nobody waits for long while the others fight twice.
        assertThat(day.longestWaitInMatches()).isLessThanOrEqualTo(6);
        day.assertEveryoneRested();
    }

    /** The day as the server would see it, with the matches each mat played and when. */
    private static final class Day {

        record Played(UUID matchId, UUID matId, Set<UUID> people, Instant start, Instant end, boolean team) {}

        private final Random random;
        private final List<UUID> mats = new ArrayList<>();
        private final Map<UUID, Integer> matNumber = new HashMap<>();
        private final Map<UUID, List<Candidate>> individual = new LinkedHashMap<>();
        private final List<Candidate> pool = new ArrayList<>();
        private final Map<UUID, Set<UUID>> teamMembers = new HashMap<>();
        private final Map<UUID, Instant> groupCreated = new HashMap<>();
        private final Map<UUID, Integer> groupNumbers = new HashMap<>();
        private final Set<UUID> allMatches = new HashSet<>();
        private final Set<UUID> teamMatches = new HashSet<>();
        private final Map<UUID, List<UUID>> groupUnits = new HashMap<>();
        private final List<Played> played = new ArrayList<>();
        private final List<UUID> people = new ArrayList<>();
        private final Map<UUID, UUID> matchGroup = new HashMap<>();
        private final Set<UUID> teamWithIndividualWaiting = new HashSet<>();

        Day(Random random, int mats) {
            this.random = random;
            for (int i = 1; i <= mats; i++) {
                var id = UUID.randomUUID();
                this.mats.add(id);
                matNumber.put(id, i);
                individual.put(id, new ArrayList<>());
            }
        }

        UUID person() {
            var id = UUID.randomUUID();
            people.add(id);
            return id;
        }

        /**
         * Two individual groups per mat of under-10s (one with a wildcard who is real in another group, one with two)
         * and a pool of team groups for the adults, one of them with a wildcard team and a wildcard member.
         */
        void typicalPhase() {
            var later = START.plus(Duration.ofMinutes(4));
            for (int m = 0; m < mats.size(); m++) {
                individualGroup(m, List.of(), 0, START);
            }
            var first = groupUnits.values().iterator().next();
            individualGroup(0, List.of(first.get(0)), 1, later);
            individualGroup(1, List.of(first.get(1), first.get(2)), 0, later);
            teamGroup(List.of(3, 3, 3, 3), 0, START);
            teamGroup(List.of(2, 3, 2), 1, START);
            teamGroup(List.of(3, 2, 2), 1, later);
            var adult = groupUnits.get(lastGroup());
            // Someone of that group fills a team of another group in as a wildcard member.
            var wildcard = teamMembers.get(adult.get(0)).iterator().next();
            addToFirstTeam(teamGroup(List.of(2, 2, 3), 1, later), wildcard);
        }

        /** Individual and team groups arriving through the morning, their wildcards anyone already in the day. */
        void tangledPhase() {
            var groups = 3 + random.nextInt(4);
            for (int g = 0; g < groups; g++) {
                var created = START.plus(Duration.ofMinutes(3L * random.nextInt(4)));
                if (random.nextBoolean() || people.isEmpty()) {
                    var borrowed = new ArrayList<UUID>();
                    for (int i = random.nextInt(4); i > 0 && !people.isEmpty(); i--) {
                        var someone = people.get(random.nextInt(people.size()));
                        if (!borrowed.contains(someone)) {
                            borrowed.add(someone);
                        }
                    }
                    individualGroup(random.nextInt(mats.size()), borrowed, 0, created);
                } else {
                    var real = 1 + random.nextInt(4);
                    var sizes = new ArrayList<Integer>();
                    for (int i = 0; i < real; i++) {
                        sizes.add(2 + random.nextInt(2));
                    }
                    var group = teamGroup(sizes, 4 - real, created);
                    var inGroup = groupUnits.get(group).stream()
                            .flatMap(t -> teamMembers.get(t).stream())
                            .collect(Collectors.toCollection(HashSet::new));
                    for (var team : groupUnits.get(group)) {
                        // Someone of another group fills this team in (never twice in one group).
                        var someone = people.get(random.nextInt(people.size()));
                        if (random.nextBoolean() && inGroup.add(someone)) {
                            var members = new HashSet<>(teamMembers.get(team));
                            members.add(someone);
                            teamMembers.put(team, members);
                        }
                    }
                }
            }
        }

        /** People who fight in more than one group (alone or in a team). */
        long peopleInSeveralGroups() {
            var groupsOf = new HashMap<UUID, Set<UUID>>();
            groupUnits.forEach((group, units) -> {
                for (var unit : units) {
                    for (var person : teamMembers.getOrDefault(unit, Set.of(unit))) {
                        groupsOf.computeIfAbsent(person, p -> new HashSet<>()).add(group);
                    }
                }
            });
            return groupsOf.values().stream().filter(g -> g.size() > 1).count();
        }

        /** A group of 4 on mat {@code matIndex}: the given wildcards, {@code wildcards} more of nobody, the rest new. */
        UUID individualGroup(int matIndex, List<UUID> borrowed, int wildcards, Instant created) {
            var units = new ArrayList<>(borrowed);
            while (units.size() < 4 - wildcards) {
                units.add(0, person());
            }
            while (units.size() < 4) {
                units.add(person());
            }
            return group(units, created, mats.get(matIndex), false);
        }

        /** A group of teams of the given sizes, plus {@code wildcards} wildcard teams of new people: 4 in all. */
        UUID teamGroup(List<Integer> sizes, int wildcards, Instant created) {
            var units = new ArrayList<UUID>();
            for (var size : sizes) {
                units.add(team(size));
            }
            for (int i = 0; i < wildcards; i++) {
                units.add(team(2 + random.nextInt(2)));
            }
            assertThat(units).hasSize(4);
            return group(units, created, null, true);
        }

        void addToFirstTeam(UUID group, UUID person) {
            var team = groupUnits.get(group).get(0);
            var members = new HashSet<>(teamMembers.get(team));
            members.add(person);
            teamMembers.put(team, members);
        }

        private UUID team(int size) {
            var id = UUID.randomUUID();
            var members = new HashSet<UUID>();
            for (int i = 0; i < size; i++) {
                members.add(person());
            }
            teamMembers.put(id, members);
            return id;
        }

        private UUID lastGroup() {
            return groupNumbers.entrySet().stream()
                    .max(Map.Entry.comparingByValue())
                    .orElseThrow()
                    .getKey();
        }

        private UUID group(List<UUID> units, Instant created, UUID mat, boolean teams) {
            var id = UUID.randomUUID();
            groupCreated.put(id, created);
            groupNumbers.put(id, groupNumbers.size() + 1);
            groupUnits.put(id, List.copyOf(units));
            var pairs = RoundRobin.pairs();
            for (int i = 0; i < pairs.size(); i++) {
                var c = new Candidate(
                        UUID.randomUUID(),
                        id,
                        groupNumbers.get(id),
                        i,
                        units.get(pairs.get(i).red()),
                        units.get(pairs.get(i).blue()));
                allMatches.add(c.matchId());
                matchGroup.put(c.matchId(), id);
                if (teams) {
                    teamMatches.add(c.matchId());
                    pool.add(c);
                } else {
                    individual.get(mat).add(c);
                }
            }
            return id;
        }

        /** Every idle mat starts its proposal; time jumps to the next event. Groups appear at their creation. */
        void playAll() {
            var now = START;
            var freeAt = new HashMap<UUID, Instant>();
            mats.forEach(m -> freeAt.put(m, START));
            var running = new ArrayList<Played>();
            for (int step = 0; step < 5_000 && played.size() < allMatches.size(); step++) {
                var at = now;
                running.removeIf(r -> !r.end().isAfter(at));
                var context = context(now, running);
                var views = mats.stream().map(m -> view(m, at, freeAt, running)).toList();
                var picks = MatchDispatch.recommend(
                        views, visiblePool(now), context, INDIVIDUAL.plus(CHANGEOVER), TEAM.plus(CHANGEOVER));
                for (var entry : picks.entrySet()) {
                    var pick = entry.getValue();
                    var team = teamMatches.contains(pick.matchId());
                    if (team && !visible(individual.get(entry.getKey()), now).isEmpty()) {
                        teamWithIndividualWaiting.add(pick.matchId());
                    }
                    var full = team ? TEAM : INDIVIDUAL;
                    // A match ends by time, or earlier by points (not in teams: no limit).
                    var length = team || random.nextInt(3) > 0
                            ? full
                            : Duration.ofSeconds(10 + random.nextInt((int) full.toSeconds() - 10));
                    var p = new Played(
                            pick.matchId(), entry.getKey(), context.people(pick), now, now.plus(length), team);
                    running.add(p);
                    played.add(p);
                    individual.get(entry.getKey()).remove(pick);
                    pool.remove(pick);
                    freeAt.put(entry.getKey(), p.end().plus(CHANGEOVER));
                }
                var next = new ArrayList<Instant>();
                running.forEach(r -> next.add(r.end()));
                freeAt.values().stream().filter(t -> t.isAfter(at)).forEach(next::add);
                groupCreated.values().stream().filter(t -> t.isAfter(at)).forEach(next::add);
                waiting(at).forEach(c -> {
                    var ready = context.readyAt(c);
                    if (ready.isAfter(at)) {
                        next.add(ready);
                    }
                });
                if (next.isEmpty()) {
                    break;
                }
                now = next.stream().min(Comparator.naturalOrder()).orElseThrow();
            }
        }

        private List<Candidate> waiting(Instant now) {
            var all = new ArrayList<>(visiblePool(now));
            individual.values().forEach(list -> all.addAll(visible(list, now)));
            return all;
        }

        private List<Candidate> visiblePool(Instant now) {
            return visible(pool, now);
        }

        private List<Candidate> visible(List<Candidate> list, Instant now) {
            return list.stream()
                    .filter(c -> !groupCreated.get(c.groupId()).isAfter(now))
                    .toList();
        }

        private MatView view(UUID mat, Instant now, Map<UUID, Instant> freeAt, List<Played> running) {
            var last = played.stream()
                    .filter(p -> p.matId().equals(mat) && !p.end().isAfter(now))
                    .max(Comparator.comparing(Played::end));
            return new MatView(
                    mat,
                    matNumber.get(mat),
                    true,
                    freeAt.get(mat).isAfter(now)
                            || running.stream().anyMatch(r -> r.matId().equals(mat)),
                    last.map(Played::end).orElse(null),
                    last.map(Played::people).orElse(Set.of()),
                    visible(individual.get(mat), now));
        }

        private Context context(Instant now, List<Played> running) {
            var lastFought = new HashMap<UUID, Instant>();
            var groupLastPlayed = new HashMap<UUID, Instant>();
            for (var p : played) {
                if (!p.end().isAfter(now)) {
                    p.people().forEach(x -> lastFought.merge(x, p.end(), Day::later));
                    groupLastPlayed.merge(matchGroup.get(p.matchId()), p.end(), Day::later);
                }
            }
            var busy = new HashSet<UUID>();
            running.forEach(r -> busy.addAll(r.people()));
            return new Context(
                    now,
                    INDIVIDUAL.plus(CHANGEOVER),
                    lastFought,
                    groupCreated,
                    groupLastPlayed,
                    busy,
                    Set.of(),
                    teamMembers,
                    MIN_REST);
        }

        private static Instant later(Instant a, Instant b) {
            return a.isAfter(b) ? a : b;
        }

        void assertEveryMatchPlayedOnce() {
            assertThat(played).extracting(Played::matchId).doesNotHaveDuplicates();
            assertThat(played).as("matches left").hasSize(allMatches.size());
        }

        void assertNobodyInTwoMatchesAtOnce() {
            for (var a : played) {
                for (var b : played) {
                    if (a != b && a.start().isBefore(b.end()) && b.start().isBefore(a.end())) {
                        assertThat(Collections.disjoint(a.people(), b.people()))
                                .as("someone in two matches at once")
                                .isTrue();
                    }
                }
            }
        }

        void assertEveryoneRested() {
            for (var person : people) {
                var mine = played.stream()
                        .filter(p -> p.people().contains(person))
                        .sorted(Comparator.comparing(Played::start))
                        .toList();
                for (int i = 1; i < mine.size(); i++) {
                    assertThat(Duration.between(
                                    mine.get(i - 1).end(), mine.get(i).start()))
                            .as("rest between two matches")
                            .isGreaterThanOrEqualTo(MIN_REST);
                }
            }
        }

        /** A mat took a team match only with no individual match of its own waiting to start. */
        void assertTeamMatchesOnlyOnMatsFreeOfIndividualMatches() {
            assertThat(teamWithIndividualWaiting).isEmpty();
        }

        Map<Integer, Long> teamMatchesPerMat() {
            var result = new java.util.TreeMap<Integer, Long>();
            played.stream().filter(Played::team).forEach(p -> result.merge(matNumber.get(p.matId()), 1L, Long::sum));
            return result;
        }

        /** The most matches anyone in a group waits between two of their own, counted on the only mat. */
        int longestWaitInMatches() {
            var order =
                    played.stream().sorted(Comparator.comparing(Played::start)).toList();
            var longest = 0;
            for (var person : people) {
                var positions = new ArrayList<Integer>();
                for (int i = 0; i < order.size(); i++) {
                    if (order.get(i).people().contains(person)) {
                        positions.add(i);
                    }
                }
                for (int i = 1; i < positions.size(); i++) {
                    longest = Math.max(longest, positions.get(i) - positions.get(i - 1) - 1);
                }
            }
            return longest;
        }
    }
}
