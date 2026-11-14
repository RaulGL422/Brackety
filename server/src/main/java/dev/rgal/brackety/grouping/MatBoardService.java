package dev.rgal.brackety.grouping;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.event.MatSync;
import dev.rgal.brackety.event.StaffNames;
import dev.rgal.brackety.grouping.dto.MatBoardResponse;
import dev.rgal.brackety.grouping.dto.MatBoardResponse.BoardGroup;
import dev.rgal.brackety.grouping.dto.MatBoardResponse.BoardMatch;
import dev.rgal.brackety.grouping.dto.MatBoardResponse.Fighter;
import dev.rgal.brackety.grouping.dto.MatBoardResponse.MatChoice;
import dev.rgal.brackety.grouping.dto.MatOverview;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Comparator;
import java.util.HashMap;
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
    private final GroupMemberRepository members;
    private final MatFloor floor;
    private final EventCategoryRepository categories;
    private final EventService events;
    private final EventAccess access;
    private final MatSchedule schedule;
    private final Clock clock;
    private final StaffNames staffNames;
    private final MatSync matSync;

    MatBoardService(
            MatRepository mats,
            GroupMemberRepository members,
            MatFloor floor,
            EventCategoryRepository categories,
            EventService events,
            EventAccess access,
            MatSchedule schedule,
            Clock clock,
            StaffNames staffNames,
            MatSync matSync) {
        this.matSync = matSync;
        this.mats = mats;
        this.members = members;
        this.floor = floor;
        this.categories = categories;
        this.events = events;
        this.access = access;
        this.schedule = schedule;
        this.clock = clock;
        this.staffNames = staffNames;
    }

    /**
     * Every mat of the event with its load and estimated end. Team matches of the pool count on the mat whose
     * expected queue has them (as its board shows), and their groups too: before they start they have no mat.
     */
    @Transactional(readOnly = true)
    List<MatOverview> overview(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB, EventRole.GROUPER);
        var now = clock.instant();
        var event = events.get(eventId);
        var states = schedule.states(event, now);
        var referees = staffNames.labels(eventId);
        var floor = this.floor.load(event, now);
        var plan = MatPlanner.simulate(event, floor, now);
        var poolMatches = floor.matches().stream()
                .filter(m -> m.getMatId() == null)
                .collect(Collectors.toMap(Match::getId, Function.identity()));
        return states.stream()
                .map(s -> {
                    var planned = plan.getOrDefault(s.mat().getId(), List.of());
                    var pool = planned.stream()
                            .map(p -> poolMatches.get(p.matchId()))
                            .filter(m -> m != null)
                            .toList();
                    var poolGroups = (int)
                            pool.stream().map(Match::getGroupId).distinct().count();
                    // With team matches of the pool, its queue ends when its last expected match does; never before
                    // what
                    // its own matches need.
                    var remaining = pool.isEmpty()
                            ? s.remaining()
                            : max(
                                    s.remaining(),
                                    Duration.between(now, planned.getLast().startsAt())
                                            .plus(MatFloor.slot(
                                                    event,
                                                    poolMatches.containsKey(
                                                            planned.getLast().matchId()))));
                    return new MatOverview(
                            s.mat().getId(),
                            s.mat().getNumber(),
                            referees.get(s.mat().getRefereeAccountId()),
                            s.groups() + poolGroups,
                            s.pendingMatches() + pool.size(),
                            s.matchInProgress(),
                            s.matchesInReview(),
                            remaining.toSeconds(),
                            now.plus(remaining));
                })
                .toList();
    }

    private static Duration max(Duration a, Duration b) {
        return a.compareTo(b) >= 0 ? a : b;
    }

    /** For the mat's referee and the club. */
    @Transactional(readOnly = true)
    MatBoardResponse board(UUID matId, UUID accountId) {
        var mat = mats.findById(matId).orElseThrow(EventException::notFound);
        requireBoardAccess(mat, accountId);
        var event = events.get(mat.getEventId());
        var now = clock.instant();
        if (accountId.equals(mat.getRefereeAccountId())) {
            matSync.seen(matId);
        }

        var floor = this.floor.load(event, now);
        var teamPool = floor.takesPool(matId);
        // Each mat's own expected queue (Raul, 2026-11-13): its matches and the team matches it would take, in the
        // order they would come up; recomputed on every change, so it moves only when reality does.
        var plannedMat = new HashMap<UUID, UUID>();
        var plannedAt = new HashMap<UUID, Instant>();
        MatPlanner.simulate(event, floor, now)
                .forEach((planMat, planned) -> planned.forEach(p -> {
                    plannedMat.put(p.matchId(), planMat);
                    plannedAt.put(p.matchId(), p.startsAt());
                }));
        var onMat = floor.matches().stream()
                .filter(m -> matId.equals(m.getMatId())
                        || (m.getMatId() == null
                                && (matId.equals(plannedMat.get(m.getId()))
                                        || (teamPool && !plannedMat.containsKey(m.getId())))))
                .sorted(Comparator.comparing((Match m) -> plannedAt.getOrDefault(m.getId(), Instant.MAX))
                        .thenComparingInt(
                                m -> floor.groups().get(m.getGroupId()).getNumber())
                        .thenComparingInt(Match::getOrderIndex))
                .toList();
        var shownGroups = onMat.stream().map(Match::getGroupId).collect(Collectors.toSet());
        var matGroups = floor.groups().values().stream()
                .filter(g -> matId.equals(g.getMatId()) || shownGroups.contains(g.getId()))
                .sorted(Comparator.comparingInt(FightGroup::getNumber))
                .toList();
        var groupById = matGroups.stream().collect(Collectors.toMap(FightGroup::getId, Function.identity()));
        var groupMembers = members.findByGroupIdInOrderByPosition(groupById.keySet());
        var ghosts = groupMembers.stream()
                .filter(GroupMember::isGhost)
                .collect(Collectors.groupingBy(
                        GroupMember::getGroupId, Collectors.mapping(GroupMember::getCompetitorId, Collectors.toSet())));
        var competitors = floor.competitors();
        var categoryNames = categories.findByEventIdOrderByMinAge(event.getId()).stream()
                .collect(Collectors.toMap(EventCategory::getId, EventCategory::getName));
        var labels = staffNames.labels(event.getId());

        var proposal = floor.proposals().get(matId);
        var recommended = proposal == null ? null : proposal.matchId();

        BiFunction<UUID, UUID, Fighter> fighter = (groupId, id) -> fighter(
                competitors.get(id), ghosts.getOrDefault(groupId, Set.of()).contains(id));
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
                        .map(m -> boardMatch(event, floor, matId, m, fighter, plannedAt.get(m.getId())))
                        .toList(),
                recommended,
                teamPool,
                mat.getEventId(),
                floor.mats().stream()
                        .map(x -> new MatChoice(x.getId(), x.getNumber(), x.getRefereeAccountId() != null))
                        .toList(),
                matSync.waitingFor(event.getId(), floor.mats()));
    }

    private static BoardMatch boardMatch(
            Event event,
            MatFloor.Floor floor,
            UUID matId,
            Match m,
            BiFunction<UUID, UUID, Fighter> fighter,
            Instant plannedAt) {
        var pending = m.getStatus() == Match.Status.PENDING;
        var wait = pending ? floor.waitOf(m, matId) : null;
        return new BoardMatch(
                m.getId(),
                m.getGroupId(),
                floor.groups().get(m.getGroupId()).getNumber(),
                m.getOrderIndex(),
                fighter.apply(m.getGroupId(), m.getRedId()),
                fighter.apply(m.getGroupId(), m.getBlueId()),
                m.getStatus(),
                m.getRedScore(),
                m.getBlueScore(),
                // Proposed to another mat (or someone in it) is only a hint: if that mat stalls, this one may take it.
                m.getStatus() == Match.Status.PENDING
                        && (wait == null || wait == MatFloor.Wait.OTHER_MAT || wait == MatFloor.Wait.RESERVED),
                m.isInReview(),
                wait == null ? null : wait.name(),
                wait == MatFloor.Wait.RESTING ? floor.readyAt(m) : null,
                switch (wait) {
                    case OTHER_MAT -> floor.proposedTo(m).map(floor::matNumber).orElse(null);
                    case RESERVED ->
                        floor.reservedBy(m, matId).map(floor::matNumber).orElse(null);
                    case null, default -> null;
                },
                m.getMatId() == null,
                pending ? floor.corner(m, m.getRedId(), event) : null,
                pending ? floor.corner(m, m.getBlueId(), event) : null,
                pending ? plannedAt : null);
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
}
