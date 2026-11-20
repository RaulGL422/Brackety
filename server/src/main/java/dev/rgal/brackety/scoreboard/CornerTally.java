package dev.rgal.brackety.scoreboard;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/** What one corner has in a match: points, warnings and the actions that scored, for the tiebreak. */
final class CornerTally {

    int points;
    int warnings;
    int oneHandWarnings;
    // The value of each scoring action still in force; not the points of the rival's warnings.
    private final List<Integer> actions = new ArrayList<>();

    void score(int value) {
        points += value;
        actions.add(value);
    }

    void takeBack(int value) {
        points = Math.max(0, points - value);
        actions.remove(Integer.valueOf(value));
    }

    void clear() {
        points = 0;
        warnings = 0;
        oneHandWarnings = 0;
        actions.clear();
    }

    /**
     * Positive when {@code red} leads, negative when {@code blue} does, 0 on a tie. With {@code tiebreaks} (grappling,
     * art. 31), a tie on points goes to the action of most value, then how many of it, then fewer warnings: a 4
     * beats any number of 2s, two 2s beat one 2, and one 2 each is a tie whatever else they scored.
     */
    static int compare(CornerTally red, CornerTally blue, boolean tiebreaks) {
        var byPoints = Integer.compare(red.points, blue.points);
        if (byPoints != 0 || !tiebreaks) {
            return byPoints;
        }
        var byBest = Integer.compare(red.best(), blue.best());
        if (byBest != 0) {
            return byBest;
        }
        var byCount = Long.compare(red.countOf(red.best()), blue.countOf(blue.best()));
        if (byCount != 0) {
            return byCount;
        }
        return Integer.compare(blue.warnings + blue.oneHandWarnings, red.warnings + red.oneHandWarnings);
    }

    private int best() {
        return actions.stream().max(Comparator.naturalOrder()).orElse(0);
    }

    private long countOf(int value) {
        return actions.stream().filter(v -> v == value).count();
    }
}
