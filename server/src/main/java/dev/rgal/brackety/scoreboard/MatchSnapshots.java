package dev.rgal.brackety.scoreboard;

import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.grouping.Match;
import dev.rgal.brackety.scoreboard.dto.MatchView;
import java.time.Clock;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/** A match as the scoreboard sees it now (points, warnings, how it ended), for other features to show. */
@Component
public class MatchSnapshots {

    private final ScoreboardService scoreboard;
    private final EventService events;
    private final Clock clock;

    MatchSnapshots(ScoreboardService scoreboard, EventService events, Clock clock) {
        this.scoreboard = scoreboard;
        this.events = events;
        this.clock = clock;
    }

    /** No access check: callers do it. */
    @Transactional(readOnly = true)
    public MatchView of(Match match) {
        return scoreboard.view(match, scoreboard.mat(match), events.get(match.getEventId()), clock.instant());
    }
}
