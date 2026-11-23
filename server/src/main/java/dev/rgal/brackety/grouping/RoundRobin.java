package dev.rgal.brackety.grouping;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Nordic system: everyone in the group fights everyone, round by round (circle method), so each round has every
 * fighter once at most. With an odd size one fighter rests each round. A group of 4 keeps the order it always had:
 * 1-2, 3-4, 1-3, 2-4, 1-4, 2-3.
 */
final class RoundRobin {

    /** Positions in the group; red is the first, blue the second. */
    record Pair(int red, int blue) {}

    private RoundRobin() {}

    /**
     * Every pair once; with {@code returnLeg}, after the whole first leg, every pair again with the colours swapped.
     */
    static List<Pair> pairs(int size, boolean returnLeg) {
        var first = firstLeg(size);
        var all = new ArrayList<>(first);
        if (returnLeg) {
            first.forEach(p -> all.add(new Pair(p.blue(), p.red())));
        }
        return all;
    }

    private static List<Pair> firstLeg(int size) {
        // An odd group gets a rest slot: whoever meets it does not fight that round.
        var slots = size % 2 == 0 ? size : size + 1;
        var circle = new ArrayList<Integer>();
        for (int i = 0; i < slots; i++) {
            circle.add(i);
        }
        var rounds = new ArrayList<List<Pair>>();
        for (int round = 0; round < slots - 1; round++) {
            var pairs = new ArrayList<Pair>();
            for (int i = 0; i < slots / 2; i++) {
                int a = circle.get(i);
                int b = circle.get(slots - 1 - i);
                if (a < size && b < size) {
                    pairs.add(new Pair(Math.min(a, b), Math.max(a, b)));
                }
            }
            pairs.sort(Comparator.comparingInt(Pair::red));
            rounds.add(pairs);
            // The first stays; the rest turn one place.
            circle.add(1, circle.remove(slots - 1));
        }
        // The round where the first meets the second goes first, then the third...: 1-2, 3-4, 1-3, 2-4... for 4.
        rounds.sort(Comparator.comparingInt(RoundRobin::firstsRival));
        return rounds.stream().flatMap(List::stream).toList();
    }

    private static int firstsRival(List<Pair> round) {
        return round.stream()
                .filter(p -> p.red() == 0)
                .mapToInt(Pair::blue)
                .findFirst()
                .orElse(Integer.MAX_VALUE);
    }
}
