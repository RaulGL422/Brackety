package dev.rgal.brackety.scoreboard;

import dev.rgal.brackety.event.ScoringRules;
import java.time.Duration;

/**
 * What a match is scored by: its length and limit, and how its sport scores ({@link ScoringRules}, kept by the
 * event's modality). {@code pointsLimit}: 0 = no limit (team matches, grappling).
 */
record MatchRules(Duration length, int pointsLimit, ScoringRules scoring) {

    boolean hasLimit() {
        return pointsLimit > 0;
    }
}
