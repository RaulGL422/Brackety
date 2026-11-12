package dev.rgal.brackety.ranking;

import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.grouping.CompetitorDirectory;
import dev.rgal.brackety.grouping.Match;
import dev.rgal.brackety.grouping.MatchRepository;
import dev.rgal.brackety.grouping.TeamMember;
import dev.rgal.brackety.grouping.TeamMemberRepository;
import dev.rgal.brackety.ranking.dto.ParticipantRecord;
import dev.rgal.brackety.ranking.dto.ParticipantRecord.RecordMatch;
import dev.rgal.brackety.scoreboard.MatchSnapshots;
import dev.rgal.brackety.scoreboard.Side;
import java.util.Comparator;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** What the club sees when it opens a participant: their standing and every match, with its warnings. */
@Service
class ParticipantRecordService {

    private final StandingsService standings;
    private final EventService events;
    private final EventAccess access;
    private final MatchRepository matches;
    private final CompetitorDirectory directory;
    private final TeamMemberRepository teamMembers;
    private final MatchSnapshots snapshots;

    ParticipantRecordService(
            StandingsService standings,
            EventService events,
            EventAccess access,
            MatchRepository matches,
            CompetitorDirectory directory,
            TeamMemberRepository teamMembers,
            MatchSnapshots snapshots) {
        this.standings = standings;
        this.events = events;
        this.access = access;
        this.matches = matches;
        this.directory = directory;
        this.teamMembers = teamMembers;
        this.snapshots = snapshots;
    }

    @Transactional(readOnly = true)
    ParticipantRecord record(UUID eventId, UUID participantId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        var event = events.get(eventId);
        var standing = standings.rows(event).stream()
                .filter(r -> r.participantId().equals(participantId))
                .findFirst()
                .orElseThrow(EventException::notFound);
        var competitors = directory.of(eventId);
        // Teams they only fill in: they fight there but score nothing.
        var ghostIn = teamMembers.findByEventId(eventId).stream()
                .filter(m -> m.isGhost() && m.getParticipantId().equals(participantId))
                .map(TeamMember::getTeamId)
                .collect(Collectors.toSet());
        var fought = matches.findByEventId(eventId).stream()
                .filter(m ->
                        competitors.participants(m.getRedId(), m.getBlueId()).contains(participantId))
                .sorted(Comparator.comparing(Match::getMatId).thenComparingInt(Match::getOrderIndex))
                .map(m -> {
                    var side = competitors.participants(m.getRedId()).contains(participantId) ? Side.RED : Side.BLUE;
                    var view = snapshots.of(m);
                    var own = side == Side.RED ? view.red() : view.blue();
                    var rival = side == Side.RED ? view.blue() : view.red();
                    return new RecordMatch(
                            m.getId(),
                            view.matNumber(),
                            view.groupNumber(),
                            view.status().name(),
                            side.name(),
                            own.ghost() || (own.teamId() != null && ghostIn.contains(own.teamId())),
                            own.teamNumber(),
                            rival.name(),
                            own.points(),
                            rival.points(),
                            own.warnings(),
                            own.oneHandWarnings(),
                            own.disqualified(),
                            rival.disqualified(),
                            view.endReason());
                })
                .sorted(Comparator.comparingInt(RecordMatch::matNumber).thenComparingInt(RecordMatch::groupNumber))
                .toList();
        return new ParticipantRecord(standing, fought);
    }
}
