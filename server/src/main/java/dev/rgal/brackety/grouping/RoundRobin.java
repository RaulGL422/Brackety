package dev.rgal.brackety.grouping;

import java.util.List;

/** Nordic system for a group of 4: everyone fights everyone, alternating so nobody fights twice in a row. */
final class RoundRobin {

    static final int GROUP_SIZE = 4;

    /** Positions 0-3 in the group; red is the first, blue the second. */
    record Pair(int red, int blue) {}

    private static final List<Pair> PAIRS =
            List.of(new Pair(0, 1), new Pair(2, 3), new Pair(0, 2), new Pair(1, 3), new Pair(0, 3), new Pair(1, 2));

    private RoundRobin() {}

    static List<Pair> pairs() {
        return PAIRS;
    }
}
