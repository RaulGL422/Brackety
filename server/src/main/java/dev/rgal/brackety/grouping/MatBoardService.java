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
import dev.rgal.brackety.event.StaffNames;
import dev.rgal.brackety.grouping.dto.MatBoardResponse;
import dev.rgal.brackety.grouping.dto.MatBoardResponse.BoardGroup;
import dev.rgal.brackety.grouping.dto.MatBoardResponse.BoardMatch;
import dev.rgal.brackety.grouping.dto.MatBoardResponse.Fighter;
import dev.rgal.brackety.grouping.dto.MatOverview;
import java.time.Clock;
import java.util.Comparator;
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

    MatBoardService(
            MatRepository mats,
            GroupMemberRepository members,
            MatFloor floor,
            EventCategoryRepository categories,
            EventService events,
            EventAccess access,
            MatSchedule schedule,
            Clock clock,
            StaffNames staffNames) {
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

        var floor = this.floor.load(event, now);
        var teamPool = floor.takesPool(matId);
        var onMat = floor.matches().stream()
                .filter(m -> matId.equals(m.getMatId()) || (teamPool && m.getMatId() == null))
                .sorted(Comparator.comparingInt(
                                (Match m) -> floor.groups().get(m.getGroupId()).getNumber())
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
                        .map(m -> boardMatch(event, floor, matId, m, fighter))
                        .toList(),
                recommended,
                teamPool,
                mat.getEventId());
    }

    private static BoardMatch boardMatch(
            Event event, MatFloor.Floor floor, UUID matId, Match m, BiFunction<UUID, UUID, Fighter> fighter) {
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
                // Proposed to another mat is only a hint: if that mat stalls, this one may take it.
                m.getStatus() == Match.Status.PENDING && (wait == null || wait == MatFloor.Wait.OTHER_MAT),
                m.isInReview(),
                wait == null ? null : wait.name(),
                wait == MatFloor.Wait.RESTING ? floor.readyAt(m) : null,
                wait == MatFloor.Wait.OTHER_MAT
                        ? floor.proposedTo(m).map(floor::matNumber).orElse(null)
                        : null,
                m.getMatId() == null,
                pending ? floor.corner(m, m.getRedId(), event) : null,
                pending ? floor.corner(m, m.getBlueId(), event) : null);
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
