package dev.rgal.brackety.event.sport;

import dev.rgal.brackety.event.MeasureRequirement;
import dev.rgal.brackety.event.Modality;
import dev.rgal.brackety.event.Modality.FormatRules;
import dev.rgal.brackety.event.ScoringRules;
import java.util.List;
import java.util.Map;

/**
 * What a sport's version says, stored as JSON: its names by language, whether it has a scoreboard yet, the measures
 * and warning reasons it asks, and the match rules a new event starts from. Without a scoreboard the match rules are
 * null: such a sport is listed but cannot be chosen.
 */
public record SportRules(
        Map<String, String> names,
        boolean scoreboard,
        MeasureRequirement weight,
        MeasureRequirement height,
        List<String> warningReasons,
        FormatRules individual,
        FormatRules team,
        int minRestSeconds,
        int changeoverSeconds,
        ScoringRules scoring) {

    public SportRules {
        names = Map.copyOf(names);
        warningReasons = warningReasons == null ? List.of() : List.copyOf(warningReasons);
    }

    /** The rules a new event of this sport starts with; the club changes what it needs. */
    public Modality modality() {
        return Modality.of(
                individual.matchSeconds(),
                individual.pointsLimit(),
                team.matchSeconds(),
                team.pointsLimit(),
                minRestSeconds,
                changeoverSeconds,
                scoring);
    }
}
