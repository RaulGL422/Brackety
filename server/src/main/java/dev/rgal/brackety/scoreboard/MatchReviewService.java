package dev.rgal.brackety.scoreboard;

import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.grouping.FightGroupRepository;
import dev.rgal.brackety.grouping.MatchRepository;
import dev.rgal.brackety.scoreboard.RejectedOp.Resolution;
import dev.rgal.brackety.scoreboard.dto.ReviewRequest;
import dev.rgal.brackety.scoreboard.dto.ReviewResponse;
import java.time.Clock;
import java.util.ArrayList;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** The club applies or discards the device actions of a match in review (docs/modulos/offline.md). */
@Service
class MatchReviewService {

    private static final Logger log = LoggerFactory.getLogger(MatchReviewService.class);

    private final MatchRepository matches;
    private final FightGroupRepository groups;
    private final MatchEventRepository matchEvents;
    private final RejectedOpRepository rejectedOps;
    private final EventService events;
    private final EventAccess access;
    private final MatchWriter writer;
    private final ScoreboardService scoreboard;
    private final Clock clock;

    MatchReviewService(
            MatchRepository matches,
            FightGroupRepository groups,
            MatchEventRepository matchEvents,
            RejectedOpRepository rejectedOps,
            EventService events,
            EventAccess access,
            MatchWriter writer,
            ScoreboardService scoreboard,
            Clock clock) {
        this.matches = matches;
        this.groups = groups;
        this.matchEvents = matchEvents;
        this.rejectedOps = rejectedOps;
        this.events = events;
        this.access = access;
        this.writer = writer;
        this.scoreboard = scoreboard;
        this.clock = clock;
    }

    /**
     * APPLY appends the rejected actions in order at their time, without checking {@code knownEvents} nor
     * fighters on other mats; those the rules refuse are skipped. Either way the match leaves the review.
     */
    @Transactional
    ReviewResponse review(UUID matchId, UUID accountId, ReviewRequest request) {
        var match = matches.lockById(matchId).orElseThrow(EventException::notFound);
        access.require(match.getEventId(), accountId, EventRole.CLUB);
        if (!match.isInReview()) {
            throw EventException.conflict("MATCH_NOT_IN_REVIEW", "The match is not in review.");
        }
        var event = events.get(match.getEventId());
        var now = clock.instant();
        var history = new ArrayList<>(matchEvents.findByMatchIdOrderByPosition(matchId));
        int applied = 0;
        int skipped = 0;
        for (var op : rejectedOps.findByMatchIdAndResolutionIsNullOrderByPosition(matchId)) {
            var resolution = Resolution.DISCARDED;
            if (request.action() == ReviewRequest.Action.APPLY) {
                // A pool match started offline goes to the mat of the referee who started it.
                if (match.getMatId() == null) {
                    scoreboard.refereeMatOf(match, op.getActorAccountId()).ifPresent(m -> match.takeMat(m.getId()));
                }
                var at = MatchWriter.effectiveTime(history, op.getAt(), now);
                var refused = writer.append(match, event, history, op.action(), at, false);
                resolution = refused.isPresent() ? Resolution.SKIPPED : Resolution.APPLIED;
                applied += refused.isPresent() ? 0 : 1;
                skipped += refused.isPresent() ? 1 : 0;
            }
            op.resolve(resolution, accountId, now);
        }
        match.endReview();
        match.backToPoolIf(groups.findById(match.getGroupId()).orElseThrow());
        var mat = scoreboard.matOrNull(match);
        log.info("Match {} review {}: {} applied, {} skipped", matchId, request.action(), applied, skipped);
        return new ReviewResponse(scoreboard.view(match, mat, event, now), applied, skipped);
    }
}
