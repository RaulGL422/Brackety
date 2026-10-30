package dev.rgal.brackety.scoreboard;

/** Corner of a fighter: red is the first of the pair, blue the second. */
public enum Side {
    RED,
    BLUE;

    Side opponent() {
        return this == RED ? BLUE : RED;
    }
}
