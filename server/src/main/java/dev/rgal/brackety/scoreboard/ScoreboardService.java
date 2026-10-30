package dev.rgal.brackety.scoreboard;

import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.grouping.FightGroupRepository;
import dev.rgal.brackety.grouping.GroupMember;
import dev.rgal.brackety.grouping.GroupMemberRepository;
import dev.rgal.brackety.grouping.Match;
import dev.rgal.brackety.grouping.MatchRepository;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import dev.rgal.brackety.scoreboard.TamboMatch.Rules;
import dev.rgal.brackety.scoreboard.dto.MatchEventRequest;
import dev.rgal.brackety.scoreboard.dto.MatchView;
import dev.rgal.brackety.scoreboard.dto.MatchView.Corner;
import dev.rgal.brackety.scoreboard.dto.MatchView.TimelineEntry;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class ScoreboardService {

    // Reglamento tambo: under 8, touching with one hand is warned and, twice, scores for the rival.
    static final int ONE_HAND_MIN_AGE = 4;
    static final int ONE_HAND_MAX_AGE = 7;

    private static final Set<MatchEventType> NEED_SIDE = EnumSet.of(
            MatchEventType.POINT,
            MatchEventType.WARNING,
            MatchEventType.ONE_HAND_WARNING,
            MatchEventType.DISQUALIFICATION);
    private static final Set<MatchEventType> NEED_REASON =
            EnumSet.of(MatchEventType.WARNING, MatchEventType.ONE_HAND_WARNING, MatchEventType.DISQUALIFICATION);

    private final MatchRepository matches;
    private final MatchEventRepository matchEvents;
    private final MatRepository mats;
    private final FightGroupRepository groups;
    private final GroupMemberRepository members;
    private final ParticipantRepository participants;
    private final AccountRepository accounts;
    private final EventService events;
    private final EventAccess access;
    private final Clock clock;

    ScoreboardService(
            MatchRepository matches,
            MatchEventRepository matchEvents,
            MatRepository mats,
            FightGroupRepository groups,
            GroupMemberRepository members,
            ParticipantRepository participants,
            AccountRepository accounts,
            EventService events,
            EventAccess access,
            Clock clock) {
        this.matches = matches;
        this.matchEvents = matchEvents;
        this.mats = mats;
        this.groups = groups;
        this.members = members;
        this.participants = participants;
        this.accounts = accounts;
        this.events = events;
        this.access = access;
        this.clock = clock;
    }

    /** For the mat's referee and the club (who follows the timeline). */
    @Transactional(readOnly = true)
    MatchView view(UUID matchId, UUID accountId) {
        var match = matches.findById(matchId).orElseThrow(EventException::notFound);
        var mat = mat(match);
        var roles = access.roles(mat.getEventId(), accountId);
        if (roles.isEmpty()) {
            throw EventException.notFound();
        }
        if (!roles.contains(EventRole.CLUB) && !isReferee(mat, accountId, roles)) {
            throw EventException.forbidden();
        }
        return view(match, mat, events.get(mat.getEventId()), clock.instant());
    }

    /** Only the referee of the mat writes its matches. */
    @Transactional
    MatchView record(UUID matchId, UUID accountId, MatchEventRequest request) {
        var match = matches.lockById(matchId).orElseThrow(EventException::notFound);
        var mat = mat(match);
        var roles = access.roles(mat.getEventId(), accountId);
        if (roles.isEmpty()) {
            throw EventException.notFound();
        }
        if (!isReferee(mat, accountId, roles)) {
            throw EventException.forbidden();
        }
        var event = events.get(mat.getEventId());
        var type = request.type();
        var side = NEED_SIDE.contains(type) ? request.side() : null;
        var reason = request.reason() == null ? "" : request.reason().strip();
        if (NEED_SIDE.contains(type) && side == null) {
            throw EventException.invalid("Say which fighter.");
        }
        if (NEED_REASON.contains(type) && reason.isEmpty()) {
            throw EventException.invalid("A warning or disqualification needs a reason.");
        }

        var now = clock.instant();
        var history = new ArrayList<>(matchEvents.findByMatchIdOrderByPosition(matchId));
        var state = replay(event, history);
        state.refuse(type, now).ifPresent(refusal -> {
            throw EventException.conflict(refusal);
        });
        if (type == MatchEventType.START && !state.isStarted()) {
            checkCanStart(match);
        }
        if (type == MatchEventType.ONE_HAND_WARNING && !oneHandRule(event, fighter(match, side))) {
            throw EventException.invalid("The one-hand warning is only for fighters aged 4 to 7.");
        }
        var target =
                type == MatchEventType.UNDO ? state.lastUndoable().orElseThrow().id() : null;
        history.add(matchEvents.save(new MatchEvent(
                matchId,
                history.size(),
                type,
                side,
                NEED_REASON.contains(type) ? reason : null,
                target,
                accountId,
                false,
                now,
                state.elapsedAt(now))));

        state = replay(event, history);
        // Points or a disqualification end the match: the clock stops here and stays stopped after an undo.
        var endsNow =
                state.endReason(now).filter(r -> r != TamboMatch.EndReason.TIME).isPresent();
        if (endsNow && state.isRunning(now)) {
            history.add(matchEvents.save(new MatchEvent(
                    matchId,
                    history.size(),
                    MatchEventType.STOP,
                    null,
                    null,
                    null,
                    accountId,
                    true,
                    now,
                    state.elapsedAt(now))));
            state = replay(event, history);
        }
        match.updateFromScoreboard(
                state.corner(Side.RED).points(),
                state.corner(Side.BLUE).points(),
                state.elapsedAt(now),
                state.isRunning(now) ? now : null,
                state.disqualified() == null ? null : state.disqualified().name(),
                state.isFinished(),
                now);
        return view(match, mat, event, now);
    }

    private void checkCanStart(Match match) {
        var eventMatches = matches.findByEventId(match.getEventId());
        var inProgress = eventMatches.stream()
                .filter(m ->
                        m.getStatus() == Match.Status.IN_PROGRESS && !m.getId().equals(match.getId()))
                .toList();
        if (inProgress.stream().anyMatch(m -> m.getMatId().equals(match.getMatId()))) {
            throw EventException.conflict("Another match is in progress on this mat.");
        }
        var fighters = Set.of(match.getRedParticipantId(), match.getBlueParticipantId());
        if (inProgress.stream()
                .anyMatch(m ->
                        fighters.contains(m.getRedParticipantId()) || fighters.contains(m.getBlueParticipantId()))) {
            throw EventException.conflict("A fighter is in a match on another mat.");
        }
    }

    private MatchView view(Match match, Mat mat, Event event, Instant now) {
        var history = matchEvents.findByMatchIdOrderByPosition(match.getId());
        var state = replay(event, history);
        var group = groups.findById(match.getGroupId()).orElseThrow();
        var ghost = members.findByGroupIdInOrderByPosition(List.of(group.getId())).stream()
                .filter(GroupMember::isGhost)
                .map(GroupMember::getParticipantId)
                .findFirst()
                .orElse(null);
        var actors = accounts
                .findAllById(history.stream()
                        .map(MatchEvent::getActorAccountId)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toSet()))
                .stream()
                .collect(Collectors.toMap(Account::getId, Account::getEmail));
        var undone = history.stream()
                .map(MatchEvent::getTargetEventId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        return new MatchView(
                match.getId(),
                mat.getId(),
                mat.getNumber(),
                group.getNumber(),
                match.getStatus(),
                event.getMatchSeconds(),
                event.getPointsLimit(),
                state.remainingAt(now).toMillis(),
                state.isRunning(now),
                state.endReason(now).map(Enum::name).orElse(null),
                corner(event, state, Side.RED, fighter(match, Side.RED), ghost),
                corner(event, state, Side.BLUE, fighter(match, Side.BLUE), ghost),
                history.stream()
                        .map(e -> new TimelineEntry(
                                e.getId(),
                                e.getType(),
                                e.getSide(),
                                e.getReason(),
                                actors.get(e.getActorAccountId()),
                                e.getAt(),
                                e.getClockMs(),
                                e.isAutomatic(),
                                undone.contains(e.getId()),
                                state.gaveAutoPoint(e.getId())))
                        .toList());
    }

    private Corner corner(Event event, TamboMatch state, Side side, Participant fighter, UUID ghost) {
        var tally = state.corner(side);
        return new Corner(
                fighter.getId(),
                fighter.getFirstName() + " " + fighter.getLastName(),
                fighter.getId().equals(ghost),
                oneHandRule(event, fighter),
                tally.points(),
                tally.warnings(),
                tally.oneHandWarnings(),
                state.disqualified() == side);
    }

    private Participant fighter(Match match, Side side) {
        var id = side == Side.RED ? match.getRedParticipantId() : match.getBlueParticipantId();
        return participants.findById(id).orElseThrow();
    }

    private static boolean oneHandRule(Event event, Participant fighter) {
        var age = event.ageOf(fighter.getBirthDate());
        return age >= ONE_HAND_MIN_AGE && age <= ONE_HAND_MAX_AGE;
    }

    private static TamboMatch replay(Event event, List<MatchEvent> history) {
        return TamboMatch.replay(
                new Rules(Duration.ofSeconds(event.getMatchSeconds()), event.getPointsLimit()),
                history.stream().map(MatchEvent::toEntry).toList());
    }

    private static boolean isReferee(Mat mat, UUID accountId, Set<EventRole> roles) {
        return roles.contains(EventRole.REFEREE) && accountId.equals(mat.getRefereeAccountId());
    }

    private Mat mat(Match match) {
        return mats.findById(match.getMatId()).orElseThrow(EventException::notFound);
    }
}
