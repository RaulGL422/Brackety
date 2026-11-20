package dev.rgal.brackety.scoreboard;

import java.time.Duration;

/**
 * What a match is scored by: its length and limit, and how its sport scores (docs/reglamentos).
 * {@code pointsLimit}: 0 = no limit (team matches, grappling).
 */
record MatchRules(Duration length, int pointsLimit, Scoring scoring) {

    MatchRules(Duration length, int pointsLimit) {
        this(length, pointsLimit, Scoring.TAMBO);
    }

    boolean hasLimit() {
        return pointsLimit > 0;
    }

    /**
     * How a sport scores, apart from the length and the limit of each match.
     *
     * @param warningsPerRivalPoint every this many warnings of a fighter, the rival gets a point
     * @param warningsToDisqualify the warning that disqualifies; 0 = none
     * @param superiorityGap the points difference that ends the match; 0 = none
     * @param pointsAfterTime the last action's point still counts once the clock shows 0:00
     * @param disqualificationScores a disqualification scores 0 for the disqualified and the limit for the rival
     * @param oneHandWarnings the one-hand warning exists (tambo, ages 4 to 8)
     * @param submissions a submission ends the match
     * @param tiebreaks a tie on points is broken by the actions of more value, then fewer warnings, then extra time
     * @param maxPointValue the most one action is worth
     */
    record Scoring(
            int warningsPerRivalPoint,
            int warningsToDisqualify,
            int superiorityGap,
            boolean pointsAfterTime,
            boolean disqualificationScores,
            boolean oneHandWarnings,
            boolean submissions,
            boolean tiebreaks,
            int maxPointValue) {

        /** Liga Yoseikan, cap. 3.1, and Raul's rules of the F1 (2026-11-13). */
        static final Scoring TAMBO = new Scoring(2, 0, 0, true, true, true, false, false, 1);

        /** FELODA, November 2025: art. 29, 31, 38, 40, 41 and 44. */
        static final Scoring GRAPPLING = new Scoring(1, 4, 15, false, false, false, true, true, 4);
    }
}
