package dev.rgal.brackety.grouping;

import java.time.Duration;

/**
 * Time left on a mat: the match in progress, then each pending match with the changeover before it.
 * The estimate never uses past averages, so a stopped mat keeps pushing its end time forward.
 */
final class MatEstimate {

    private MatEstimate() {}

    /**
     * @param currentLeft clock left on the match in progress, or null if none is running
     * @param sinceLastFinished time since the last match on the mat finished, or null if none has
     */
    static Duration remaining(
            int pendingMatches, Duration currentLeft, Duration sinceLastFinished, Duration match, Duration changeover) {
        if (currentLeft != null) {
            return currentLeft.plus(match.plus(changeover).multipliedBy(pendingMatches));
        }
        if (pendingMatches == 0) {
            return Duration.ZERO;
        }
        // Only what is left of the changeover after the last match; an idle mat owes none.
        var firstGap = sinceLastFinished == null || sinceLastFinished.compareTo(changeover) >= 0
                ? Duration.ZERO
                : changeover.minus(sinceLastFinished);
        return firstGap.plus(match).plus(match.plus(changeover).multipliedBy(pendingMatches - 1L));
    }
}
