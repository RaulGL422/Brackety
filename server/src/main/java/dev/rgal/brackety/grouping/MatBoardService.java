package dev.rgal.brackety.grouping;

import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.grouping.MatchRecommender.Candidate;
import dev.rgal.brackety.grouping.dto.MatBoardResponse;
import dev.rgal.brackety.grouping.dto.MatBoardResponse.BoardGroup;
import dev.rgal.brackety.grouping.dto.MatBoardResponse.BoardMatch;
import dev.rgal.brackety.grouping.dto.MatBoardResponse.Fighter;
import dev.rgal.brackety.grouping.dto.MatOverview;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.function.BiFunction;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class MatBoardService {

    private final MatRepository mats;
    private final FightGroupRepository groups;
    private final GroupMemberRepository members;
    private final MatchRepository matches;
    private final ParticipantRepository participants;
    private final EventCategoryRepository categories;
    private final AccountRepository accounts;
    private final EventService events;
    private final EventAccess access;
    private final MatSchedule schedule;
    private final Clock clock;

    MatBoardService(
            MatRepository mats,
            FightGroupRepository groups,
            GroupMemberRepository members,
            MatchRepository matches,
            ParticipantRepository participants,
            EventCategoryRepository categories,
            AccountRepository accounts,
            EventService events,
            EventAccess access,
            MatSchedule schedule,
            Clock clock) {
        this.mats = mats;
        this.groups = groups;
        this.members = members;
        this.matches = matches;
        this.participants = participants;
        this.categories = categories;
        this.accounts = accounts;
        this.events = events;
        this.access = access;
        this.schedule = schedule;
        this.clock = clock;
    }

    /** Every mat of the event with its load and estimated end. */
    @Transactional(readOnly = true)
    List<MatOverview> overview(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB, EventRole.GROUPER);
        var now = clock.instant();
        var states = schedule.states(events.get(eventId), now);
        var referees = accounts
                .findAllById(states.stream()
                        .map(s -> s.mat().getRefereeAccountId())
                        .filter(Objects::nonNull)
                        .toList())
                .stream()
                .collect(Collectors.toMap(Account::getId, Account::getEmail));
        return states.stream()
                .map(s -> new MatOverview(
                        s.mat().getId(),
                        s.mat().getNumber(),
                        referees.get(s.mat().getRefereeAccountId()),
                        s.groups(),
                        s.pendingMatches(),
                        s.matchInProgress(),
                        s.remaining().toSeconds(),
                        now.plus(s.remaining())))
                .toList();
    }

    /** For the mat's referee and the club. */
    @Transactional(readOnly = true)
    MatBoardResponse board(UUID matId, UUID accountId) {
        var mat = mats.findById(matId).orElseThrow(EventException::notFound);
        requireBoardAccess(mat, accountId);
        var event = events.get(mat.getEventId());
        var now = clock.instant();

        var matGroups = groups.findByMatIdOrderByNumber(matId);
        var groupById = matGroups.stream().collect(Collectors.toMap(FightGroup::getId, Function.identity()));
        var groupMembers = members.findByGroupIdInOrderByPosition(groupById.keySet());
        var ghosts = groupMembers.stream()
                .filter(GroupMember::isGhost)
                .collect(Collectors.toMap(GroupMember::getGroupId, GroupMember::getParticipantId));
        var names = participants
                .findAllById(
                        groupMembers.stream().map(GroupMember::getParticipantId).collect(Collectors.toSet()))
                .stream()
                .collect(Collectors.toMap(Participant::getId, p -> p.getFirstName() + " " + p.getLastName()));
        var categoryNames = categories.findByEventIdOrderByMinAge(event.getId()).stream()
                .collect(Collectors.toMap(EventCategory::getId, EventCategory::getName));

        var eventMatches = matches.findByEventId(event.getId());
        var busy = new HashSet<UUID>();
        var lastFought = new HashMap<UUID, Instant>();
        for (var m : eventMatches) {
            if (m.getStatus() == Match.Status.IN_PROGRESS) {
                busy.add(m.getRedParticipantId());
                busy.add(m.getBlueParticipantId());
            }
            if (m.getFinishedAt() != null) {
                lastFought.merge(m.getRedParticipantId(), m.getFinishedAt(), this::later);
                lastFought.merge(m.getBlueParticipantId(), m.getFinishedAt(), this::later);
            }
        }
        var onMat = eventMatches.stream()
                .filter(m -> m.getMatId().equals(matId))
                .sorted(Comparator.comparingInt(
                                (Match m) -> groupById.get(m.getGroupId()).getNumber())
                        .thenComparingInt(Match::getOrderIndex))
                .toList();
        var groupLastPlayed = new HashMap<UUID, Instant>();
        onMat.stream()
                .filter(m -> m.getFinishedAt() != null)
                .forEach(m -> groupLastPlayed.merge(m.getGroupId(), m.getFinishedAt(), this::later));
        Set<UUID> justFought = onMat.stream()
                .filter(m -> m.getFinishedAt() != null)
                .max(Comparator.comparing(Match::getFinishedAt))
                .map(m -> Set.of(m.getRedParticipantId(), m.getBlueParticipantId()))
                .orElse(Set.of());

        var candidates = onMat.stream()
                .filter(m -> m.getStatus() == Match.Status.PENDING)
                .map(m -> new Candidate(
                        m.getId(),
                        m.getGroupId(),
                        groupById.get(m.getGroupId()).getNumber(),
                        m.getOrderIndex(),
                        m.getRedParticipantId(),
                        m.getBlueParticipantId()))
                .toList();
        var context = new MatchRecommender.Context(
                now,
                Duration.ofSeconds(event.getMatchSeconds() + event.getChangeoverSeconds()),
                lastFought,
                matGroups.stream().collect(Collectors.toMap(FightGroup::getId, FightGroup::getCreatedAt)),
                groupLastPlayed,
                busy,
                justFought);
        var recommended = MatchRecommender.recommend(candidates, context).orElse(null);

        BiFunction<UUID, UUID, Fighter> fighter = (groupId, participantId) ->
                new Fighter(participantId, names.get(participantId), participantId.equals(ghosts.get(groupId)));
        return new MatBoardResponse(
                matId,
                mat.getNumber(),
                matGroups.stream()
                        .map(g -> new BoardGroup(
                                g.getId(),
                                g.getNumber(),
                                categoryNames.get(g.getCategoryId()),
                                groupMembers.stream()
                                        .filter(m -> m.getGroupId().equals(g.getId()))
                                        .map(m -> fighter.apply(g.getId(), m.getParticipantId()))
                                        .toList()))
                        .toList(),
                onMat.stream()
                        .map(m -> new BoardMatch(
                                m.getId(),
                                m.getGroupId(),
                                groupById.get(m.getGroupId()).getNumber(),
                                m.getOrderIndex(),
                                fighter.apply(m.getGroupId(), m.getRedParticipantId()),
                                fighter.apply(m.getGroupId(), m.getBlueParticipantId()),
                                m.getStatus(),
                                m.getRedScore(),
                                m.getBlueScore(),
                                m.getStatus() == Match.Status.PENDING
                                        && !busy.contains(m.getRedParticipantId())
                                        && !busy.contains(m.getBlueParticipantId())))
                        .toList(),
                recommended);
    }

    private void requireBoardAccess(Mat mat, UUID accountId) {
        var roles = access.roles(mat.getEventId(), accountId);
        if (roles.isEmpty()) {
            throw EventException.notFound();
        }
        var ownMat = roles.contains(EventRole.REFEREE) && accountId.equals(mat.getRefereeAccountId());
        if (!roles.contains(EventRole.CLUB) && !ownMat) {
            throw EventException.forbidden();
        }
    }

    private Instant later(Instant a, Instant b) {
        return a.isAfter(b) ? a : b;
    }
}
