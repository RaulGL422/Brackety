package dev.rgal.brackety.ranking;

import dev.rgal.brackety.event.ScoringRules;
import dev.rgal.brackety.grouping.Match;
import dev.rgal.brackety.scoreboard.Side;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;

/**
 * The FELODA ranking of a group or category (docs/reglamentos/grappling-feloda-2025.md, art. 8 and 39): most wins,
 * then classification points, the match between the two tied (with a return leg, both matches: wins, then points
 * scored), wins by submission, wins by superiority and technical points. What each way of winning gives comes from the event's rules ({@link ScoringRules#classification()}).
 */
final class ClassificationStandings {

    /** One fighter's record in finished matches. */
    static final class Tally {
        int wins;
        int points;
        int submissions;
        int superiorities;
        int technical;
        final Map<UUID, Integer> winsAgainst = new HashMap<>();
        final Map<UUID, Integer> scoredAgainst = new HashMap<>();

        // Everything but the match between the two: equal here means tied unless they fought.
        private List<Integer> key() {
            return List.of(wins, points, submissions, superiorities, technical);
        }
    }

    private static final Comparator<Tally> BEST_FIRST = Comparator.<Tally>comparingInt(t -> t.wins)
            .thenComparingInt(t -> t.points)
            .thenComparingInt(t -> t.submissions)
            .thenComparingInt(t -> t.superiorities)
            .thenComparingInt(t -> t.technical)
            .reversed();

    private final Map<String, ScoringRules.Classification> byEnd = new HashMap<>();
    private final Map<UUID, Tally> tallies = new HashMap<>();

    ClassificationStandings(ScoringRules rules) {
        rules.classification().forEach(c -> byEnd.put(c.end(), c));
    }

    /** {@code red} and {@code blue}: the people who score for each side (not a wildcard's own group). */
    void add(Match match, Set<UUID> red, Set<UUID> blue) {
        if (match.getStatus() == Match.Status.FINISHED && match.getWinnerSide() != null) {
            add(
                    Side.valueOf(match.getWinnerSide()),
                    match.getEndReason(),
                    match.getRedScore(),
                    match.getBlueScore(),
                    red,
                    blue);
        }
    }

    /** A decided match: {@code winner} won it as {@code end} (a match end reason) with these scores. */
    void add(Side winner, String end, int redScore, int blueScore, Set<UUID> red, Set<UUID> blue) {
        var classification = byEnd.get(end);
        record(red, blue, winner == Side.RED, redScore, end, classification);
        record(blue, red, winner == Side.BLUE, blueScore, end, classification);
    }

    private void record(
            Set<UUID> people,
            Set<UUID> rivals,
            boolean won,
            int score,
            String end,
            ScoringRules.Classification classification) {
        for (var person : people) {
            var tally = tally(person);
            tally.technical += score;
            rivals.forEach(rival -> tally.scoredAgainst.merge(rival, score, Integer::sum));
            if (won) {
                tally.wins++;
                rivals.forEach(rival -> tally.winsAgainst.merge(rival, 1, Integer::sum));
                tally.submissions += "SUBMISSION".equals(end) ? 1 : 0;
                tally.superiorities += "SUPERIORITY".equals(end) ? 1 : 0;
            }
            if (classification != null) {
                tally.points += won
                        ? classification.winner()
                        : score > 0 ? classification.loserWhoScored() : classification.loser();
            }
        }
    }

    Tally tally(UUID person) {
        return tallies.computeIfAbsent(person, id -> new Tally());
    }

    /**
     * {@code items} best first, each with its position: equal records share it, except two whose match decides
     * between them.
     */
    <T> List<Placed<T>> rank(List<T> items, Function<T, UUID> person) {
        var sorted = new ArrayList<>(items);
        sorted.sort(Comparator.comparing(item -> tally(person.apply(item)), BEST_FIRST));
        var placed = new ArrayList<Placed<T>>();
        for (int i = 0; i < sorted.size(); ) {
            var key = tally(person.apply(sorted.get(i))).key();
            var block = new ArrayList<T>();
            while (i < sorted.size() && tally(person.apply(sorted.get(i))).key().equals(key)) {
                block.add(sorted.get(i++));
            }
            var position = placed.size() + 1;
            if (block.size() == 2) {
                var first = tally(person.apply(block.get(0)));
                var second = tally(person.apply(block.get(1)));
                var between = headToHead(first, second, person.apply(block.get(0)), person.apply(block.get(1)));
                if (between != 0) {
                    var firstWon = between > 0;
                    placed.add(new Placed<>(firstWon ? block.get(0) : block.get(1), position));
                    placed.add(new Placed<>(firstWon ? block.get(1) : block.get(0), position + 1));
                    continue;
                }
            }
            block.forEach(item -> placed.add(new Placed<>(item, position)));
        }
        return placed;
    }

    // Above 0 when the first did better against the second: wins between them, then points scored between them.
    private static int headToHead(Tally first, Tally second, UUID firstId, UUID secondId) {
        var wins = Integer.compare(
                first.winsAgainst.getOrDefault(secondId, 0), second.winsAgainst.getOrDefault(firstId, 0));
        return wins != 0
                ? wins
                : Integer.compare(
                        first.scoredAgainst.getOrDefault(secondId, 0), second.scoredAgainst.getOrDefault(firstId, 0));
    }

    record Placed<T>(T item, int position) {}
}
