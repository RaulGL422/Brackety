package dev.rgal.brackety.league;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

/**
 * How many firsts, seconds and thirds a category has on the final league standings.
 *
 * <p>The medal for a position (1-based, tied people share it): positions 1..F are gold, F+1..F+S silver and
 * F+S+1..F+S+T bronze. Ties share the medal of their position, even if that gives more medals than set. Nobody with
 * 0 points gets one.
 */
public record Podium(
        @Min(0) @Max(10) int firsts,
        @Min(0) @Max(10) int seconds,
        @Min(0) @Max(10) int thirds) {

    /** 1, 2 or 3, or null for no medal. */
    public Integer medal(int position, int total) {
        if (total <= 0) {
            return null;
        }
        if (position <= firsts) {
            return 1;
        }
        if (position <= firsts + seconds) {
            return 2;
        }
        if (position <= firsts + seconds + thirds) {
            return 3;
        }
        return null;
    }
}
