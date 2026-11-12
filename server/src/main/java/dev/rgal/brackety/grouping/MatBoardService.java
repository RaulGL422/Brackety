package dev.rgal.brackety.grouping;

import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.event.StaffNames;
import dev.rgal.brackety.grouping.MatchRecommender.Candidate;
import dev.rgal.brackety.grouping.dto.MatBoardResponse;
import dev.rgal.brackety.grouping.dto.MatBoardResponse.BoardGroup;
import dev.rgal.brackety.grouping.dto.MatBoardResponse.BoardMatch;
import dev.rgal.brackety.grouping.dto.MatBoardResponse.Fighter;
import dev.rgal.brackety.grouping.dto.MatOverview;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
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
    private final CompetitorDirectory directory;
    private final EventCategoryRepository categories;
    private final EventService events;
    private final EventAccess access;
    private final MatSchedule schedule;
    private final Clock clock;
    private final StaffNames staffNames;

    MatBoardService(
            MatRepository mats,
            FightGroupRepository groups,
            GroupMemberRepository members,
            MatchRepository matches,
            CompetitorDirectory directory,
            EventCategoryRepository categories,
            EventService events,
            EventAccess access,
            MatSchedule schedule,
            Clock clock,
            StaffNames staffNames) {
        this.mats = mats;
        this.groups = groups;
        this.members = members;
        this.matches = matches;
        this.directory = directory;
        this.categories = categories;
        this.events = events;
        this.access = access;
        this.schedule = schedule;
        this.clock = clock;
        this.staffNames = staffNames;
    }

    /** Every mat of the event with its load and estimated end. */
    @Transactional(readOnly = true)
    List<MatOverview> overview(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB, EventRole.GROUPER);
        var now = clock.instant();
        var states = schedule.states(events.get(eventId), now);
        var referees = staffNames.labels(eventId);
        return states.stream()
                .map(s -> new MatOverview(
                        s.mat().getId(),
                        s.mat().getNumber(),
                        referees.get(s.mat().getRefereeAccountId()),
                        s.groups(),
                        s.pendingMatches(),
                        s.matchInProgress(),
                        s.matchesInReview(),
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
                .collect(Collectors.toMap(GroupMember::getGroupId, GroupMember::getCompetitorId));
        var competitors = directory.of(event.getId());
        var categoryNames = categories.findByEventIdOrderByMinAge(event.getId()).stream()
                .collect(Collectors.toMap(EventCategory::getId, EventCategory::getName));
        var labels = staffNames.labels(event.getId());

        var eventMatches = matches.findByEventId(event.getId());
        var busy = new HashSet<UUID>();
        var lastFought = new HashMap<UUID, Instant>();
        for (var m : eventMatches) {
            var fighters = competitors.participants(m.getRedId(), m.getBlueId());
            if (m.getStatus() == Match.Status.IN_PROGRESS) {
                busy.addAll(fighters);
            }
            if (m.getFinishedAt() != null) {
                fighters.forEach(p -> lastFought.merge(p, m.getFinishedAt(), this::later));
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
                .map(m -> competitors.participants(m.getRedId(), m.getBlueId()))
                .orElse(Set.of());

        var candidates = onMat.stream()
                .filter(m -> m.getStatus() == Match.Status.PENDING && !m.isInReview())
                .map(m -> new Candidate(
                        m.getId(),
                        m.getGroupId(),
                        groupById.get(m.getGroupId()).getNumber(),
                        m.getOrderIndex(),
                        m.getRedId(),
                        m.getBlueId()))
                .toList();
        var context = new MatchRecommender.Context(
                now,
                Duration.ofSeconds(event.getMatchSeconds() + event.getChangeoverSeconds()),
                lastFought,
                matGroups.stream().collect(Collectors.toMap(FightGroup::getId, FightGroup::getCreatedAt)),
                groupLastPlayed,
                busy,
                justFought,
                competitors.teamMembers());
        var recommended = MatchRecommender.recommend(candidates, context).orElse(null);

        BiFunction<UUID, UUID, Fighter> fighter =
                (groupId, id) -> fighter(competitors.get(id), id.equals(ghosts.get(groupId)));
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
                                        .map(m -> fighter.apply(g.getId(), m.getCompetitorId()))
                                        .toList(),
                                labels.get(g.getCreatedBy())))
                        .toList(),
                onMat.stream()
                        .map(m -> new BoardMatch(
                                m.getId(),
                                m.getGroupId(),
                                groupById.get(m.getGroupId()).getNumber(),
                                m.getOrderIndex(),
                                fighter.apply(m.getGroupId(), m.getRedId()),
                                fighter.apply(m.getGroupId(), m.getBlueId()),
                                m.getStatus(),
                                m.getRedScore(),
                                m.getBlueScore(),
                                m.getStatus() == Match.Status.PENDING
                                        && !m.isInReview()
                                        && competitors.participants(m.getRedId(), m.getBlueId()).stream()
                                                .noneMatch(busy::contains),
                                m.isInReview()))
                        .toList(),
                recommended);
    }

    private static Fighter fighter(Competitor c, boolean ghost) {
        return new Fighter(
                c.isTeam() ? null : c.id(),
                c.isTeam() ? String.join(", ", c.memberNames()) : c.name(),
                ghost,
                c.isTeam() ? c.id() : null,
                c.teamNumber(),
                c.memberNames());
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
