package dev.rgal.brackety.scoreboard;

import dev.rgal.brackety.event.ScoringRules.Tiebreak;
import java.util.ArrayList;
import java.util.List;

/** What one corner has in a match: points, warnings and the actions that scored, for the tiebreaks. */
final class CornerTally {

    // A scoring action still in force, and its place among all the match's actions.
    private record Scored(int value, int order) {}

    int points;
    int warnings;
    int oneHandWarnings;
    // Not the points of the rival's warnings.
    private final List<Scored> actions = new ArrayList<>();

    void score(int value, int order) {
        points += value;
        actions.add(new Scored(value, order));
    }

    // The latest action of that value goes.
    void takeBack(int value) {
        points = Math.max(0, points - value);
        for (int i = actions.size() - 1; i >= 0; i--) {
            if (actions.get(i).value() == value) {
                actions.remove(i);
                return;
            }
        }
    }

    void clear() {
        points = 0;
        warnings = 0;
        oneHandWarnings = 0;
        actions.clear();
    }

    /**
     * Positive when {@code red} leads, negative when {@code blue} does, 0 on a tie. A tie on points goes through
     * {@code tiebreaks} in order; EXTRA_TIME is not decided here: the referee says who won it.
     */
    static int compare(CornerTally red, CornerTally blue, List<Tiebreak> tiebreaks) {
        var result = Integer.compare(red.points, blue.points);
        for (var tiebreak : tiebreaks) {
            if (result != 0) {
                return result;
            }
            result = switch (tiebreak) {
                // Grappling, art. 31: a 4 beats any number of 2s, two 2s beat one 2.
                case BEST_ACTION -> {
                    var byBest = Integer.compare(red.best(), blue.best());
                    yield byBest != 0 ? byBest : Long.compare(red.countOf(red.best()), blue.countOf(blue.best()));
                }
                case FEWER_WARNINGS ->
                    Integer.compare(blue.warnings + blue.oneHandWarnings, red.warnings + red.oneHandWarnings);
                case LAST_TO_SCORE -> Integer.compare(red.lastOrder(), blue.lastOrder());
                case EXTRA_TIME -> 0;
            };
        }
        return result;
    }

    private int best() {
        return actions.stream().mapToInt(Scored::value).max().orElse(0);
    }

    private long countOf(int value) {
        return actions.stream().filter(a -> a.value() == value).count();
    }

    private int lastOrder() {
        return actions.stream().mapToInt(Scored::order).max().orElse(-1);
    }
}
