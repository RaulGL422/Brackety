package dev.rgal.brackety.scoreboard;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.grouping.FightGroup;
import dev.rgal.brackety.grouping.FightGroupRepository;
import dev.rgal.brackety.grouping.Match;
import java.time.Duration;
import org.springframework.stereotype.Service;

/**
 * The one owner of the rules a match is fought by (docs/producto/modelo-datos.md): its category's length if it has
 * one, else its modality's per format, and the modality's points limit and scoring.
 */
@Service
class MatchRulesService {

    private final FightGroupRepository groups;
    private final EventCategoryRepository categories;

    MatchRulesService(FightGroupRepository groups, EventCategoryRepository categories) {
        this.groups = groups;
        this.categories = categories;
    }

    MatchRules of(Event event, Match match) {
        var teams = match.isTeamMatch();
        var modality = event.modality();
        var categoryLength = groups.findById(match.getGroupId())
                .map(FightGroup::getCategoryId)
                .flatMap(categories::findById)
                .map(EventCategory::getMatchSeconds);
        var seconds = categoryLength.orElse(modality.matchSeconds(teams));
        return new MatchRules(Duration.ofSeconds(seconds), modality.pointsLimit(teams), modality.scoring());
    }
}
