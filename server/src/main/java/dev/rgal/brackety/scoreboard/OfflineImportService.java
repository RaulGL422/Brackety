package dev.rgal.brackety.scoreboard;

import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.grouping.MatchRepository;
import dev.rgal.brackety.scoreboard.dto.MatchEventRequest;
import dev.rgal.brackety.scoreboard.dto.OfflineImportResponse;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * The club imports the actions a referee's device could not send (docs/modulos/offline.md, "Rescate"). Each goes
 * through the queue's own path, in its own transaction and in file order: a known {@code opId} changes nothing
 * and a clash puts the match in review, as if the device had sent it.
 */
@Service
class OfflineImportService {

    private static final Logger log = LoggerFactory.getLogger(OfflineImportService.class);

    record Outcome(OfflineImportResponse response, Set<UUID> changedMatches) {}

    private final ScoreboardService scoreboard;
    private final MatchRepository matches;
    private final MatchEventRepository matchEvents;
    private final RejectedOpRepository rejectedOps;
    private final EventAccess access;

    OfflineImportService(
            ScoreboardService scoreboard,
            MatchRepository matches,
            MatchEventRepository matchEvents,
            RejectedOpRepository rejectedOps,
            EventAccess access) {
        this.scoreboard = scoreboard;
        this.matches = matches;
        this.matchEvents = matchEvents;
        this.rejectedOps = rejectedOps;
        this.access = access;
    }

    Outcome importCsv(UUID eventId, UUID accountId, String csv) {
        access.require(eventId, accountId, EventRole.CLUB);
        var rows = OfflineOpsCsv.parse(csv);
        // Every row checked before any is applied: a wrong file changes nothing.
        for (var row : rows) {
            var match = matches.findById(row.matchId()).orElse(null);
            if (match == null || !match.getEventId().equals(eventId)) {
                throw EventException.invalid("Line " + row.line() + ": the match is not in this event.");
            }
        }
        int applied = 0;
        int duplicates = 0;
        int inReview = 0;
        int skipped = 0;
        var changed = new LinkedHashSet<UUID>();
        for (var row : rows) {
            if (matchEvents.existsByOpId(row.opId())
                    || rejectedOps.findByOpId(row.opId()).isPresent()) {
                duplicates++;
                continue;
            }
            var request = new MatchEventRequest(
                    row.type(), row.side(), row.reason(), row.opId(), row.at(), row.knownEvents());
            try {
                var recorded =
                        scoreboard.recordImported(row.matchId(), actor(eventId, row.actor(), accountId), request);
                if (recorded.conflictCode() == null) {
                    applied++;
                } else {
                    inReview++;
                }
                changed.add(row.matchId());
            } catch (EventException e) {
                skipped++;
            }
        }
        log.info(
                "Offline import into event {}: {} applied, {} duplicates, {} in review, {} skipped",
                eventId,
                applied,
                duplicates,
                inReview,
                skipped);
        return new Outcome(new OfflineImportResponse(applied, duplicates, inReview, skipped), changed);
    }

    // The referee who made the action, if they are on the event's staff; otherwise the club who imports it.
    private UUID actor(UUID eventId, UUID actor, UUID importer) {
        return actor != null && !access.roles(eventId, actor).isEmpty() ? actor : importer;
    }
}
