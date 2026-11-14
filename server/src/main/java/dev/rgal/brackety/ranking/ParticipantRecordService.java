package dev.rgal.brackety.ranking;

import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventRepository;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.grouping.CompetitorDirectory;
import dev.rgal.brackety.grouping.Match;
import dev.rgal.brackety.grouping.MatchRepository;
import dev.rgal.brackety.grouping.TeamMember;
import dev.rgal.brackety.grouping.TeamMemberRepository;
import dev.rgal.brackety.participant.ParticipantRepository;
import dev.rgal.brackety.ranking.dto.LeagueRecord;
import dev.rgal.brackety.ranking.dto.ParticipantRecord;
import dev.rgal.brackety.ranking.dto.ParticipantRecord.Incident;
import dev.rgal.brackety.ranking.dto.ParticipantRecord.RecordMatch;
import dev.rgal.brackety.scoreboard.MatchEventType;
import dev.rgal.brackety.scoreboard.MatchSnapshots;
import dev.rgal.brackety.scoreboard.Side;
import dev.rgal.brackety.scoreboard.dto.MatchView.TimelineEntry;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** What the club sees when it opens a participant: their standing and every match, with its warnings. */
@Service
class ParticipantRecordService {

    private static final Set<MatchEventType> INCIDENTS =
            Set.of(MatchEventType.WARNING, MatchEventType.ONE_HAND_WARNING, MatchEventType.DISQUALIFICATION);

    private final StandingsService standings;
    private final EventService events;
    private final EventRepository eventRepository;
    private final EventAccess access;
    private final MatchRepository matches;
    private final CompetitorDirectory directory;
    private final TeamMemberRepository teamMembers;
    private final ParticipantRepository participants;
    private final MatchSnapshots snapshots;

    ParticipantRecordService(
            StandingsService standings,
            EventService events,
            EventRepository eventRepository,
            EventAccess access,
            MatchRepository matches,
            CompetitorDirectory directory,
            TeamMemberRepository teamMembers,
            ParticipantRepository participants,
            MatchSnapshots snapshots) {
        this.standings = standings;
        this.events = events;
        this.eventRepository = eventRepository;
        this.access = access;
        this.matches = matches;
        this.directory = directory;
        this.teamMembers = teamMembers;
        this.participants = participants;
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
        return new ParticipantRecord(standing, matchesOf(eventId, participantId));
    }

    /** The person's matches in every phase of the event's league they entered, phase by phase. */
    @Transactional(readOnly = true)
    LeagueRecord leagueRecord(UUID eventId, UUID personId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        var event = events.get(eventId);
        var phases = eventRepository.findByLeagueIdOrderByPhaseNumber(event.getLeagueId()).stream()
                .flatMap(phase -> participants.findByEventIdOrderByFirstNameAscLastNameAsc(phase.getId()).stream()
                        .filter(p -> personId.equals(p.getPersonId()))
                        .findFirst()
                        .map(p -> new LeagueRecord.Phase(
                                phase.getId(),
                                phase.getPhaseNumber(),
                                phase.getName(),
                                matchesOf(phase.getId(), p.getId())))
                        .stream())
                .toList();
        if (phases.isEmpty()) {
            throw EventException.notFound();
        }
        return new LeagueRecord(phases);
    }

    private List<RecordMatch> matchesOf(UUID eventId, UUID participantId) {
        var competitors = directory.of(eventId);
        // Teams they only fill in: they fight there but score nothing.
        var ghostIn = teamMembers.findByEventId(eventId).stream()
                .filter(m -> m.isGhost() && m.getParticipantId().equals(participantId))
                .map(TeamMember::getTeamId)
                .collect(Collectors.toSet());
        return matches.findByEventId(eventId).stream()
                .filter(m ->
                        competitors.participants(m.getRedId(), m.getBlueId()).contains(participantId))
                .sorted(Comparator.comparing(Match::getMatId, Comparator.nullsLast(Comparator.naturalOrder()))
                        .thenComparingInt(Match::getOrderIndex))
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
                            view.endReason(),
                            incidents(view.timeline(), side));
                })
                .sorted(Comparator.comparing(RecordMatch::matNumber, Comparator.nullsLast(Comparator.naturalOrder()))
                        .thenComparingInt(RecordMatch::groupNumber))
                .toList();
    }

    // Those of their side that stand: a cancel starts the match over, as the scoreboard does (TamboMatch).
    private static List<Incident> incidents(List<TimelineEntry> timeline, Side side) {
        var lastCancel = -1;
        for (int i = 0; i < timeline.size(); i++) {
            if (timeline.get(i).type() == MatchEventType.CANCEL
                    && !timeline.get(i).undone()) {
                lastCancel = i;
            }
        }
        return timeline.subList(lastCancel + 1, timeline.size()).stream()
                .filter(e -> INCIDENTS.contains(e.type()) && e.side() == side && !e.undone())
                .map(e -> new Incident(e.type().name(), e.reason(), e.clockMs(), e.actor(), e.gaveRivalPoint()))
                .toList();
    }
}
