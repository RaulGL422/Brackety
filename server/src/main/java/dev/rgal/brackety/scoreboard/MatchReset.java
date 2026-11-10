package dev.rgal.brackety.scoreboard;

import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.grouping.MatchRepository;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** The superadmin restarts a match: as if it had never been started. */
@Service
public class MatchReset {

    private final MatchRepository matches;
    private final MatchEventRepository events;
    private final RejectedOpRepository rejected;

    MatchReset(MatchRepository matches, MatchEventRepository events, RejectedOpRepository rejected) {
        this.matches = matches;
        this.events = events;
        this.rejected = rejected;
    }

    /**
     * Its actions, the device actions kept for the club's review and its score go; the match is pending
     * again. Under the match's row lock, like every scoreboard write. Returns the match's event.
     */
    @Transactional
    public UUID reset(UUID matchId) {
        var match = matches.lockById(matchId).orElseThrow(EventException::notFound);
        rejected.deleteByMatchId(matchId);
        events.deleteByMatchId(matchId);
        // The deletes cleared the persistence context: the match is read again before changing it.
        var fresh = matches.findById(matchId).orElseThrow(EventException::notFound);
        fresh.reset();
        return match.getEventId();
    }
}
