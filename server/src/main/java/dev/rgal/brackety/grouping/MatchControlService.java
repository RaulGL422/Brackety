package dev.rgal.brackety.grouping;

import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import java.time.Clock;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * The control panel of the club and the superadmin (Raul, 2026-11-13: "tener yo el control de todo"): move a group
 * or a pending match to another mat, change the order of a group's pending matches, move a person between teams of
 * groups that have not started, and let a match start without the least rest. {@code by} is the club account, or
 * null for the superadmin (whose API has no event role). Every change locks the event, as a first start does.
 */
@Service
public class MatchControlService {

    private static final Logger log = LoggerFactory.getLogger(MatchControlService.class);

    private final MatchRepository matches;
    private final FightGroupRepository groups;
    private final MatRepository mats;
    private final TeamRepository teams;
    private final TeamMemberRepository teamMembers;
    private final GroupMemberRepository groupMembers;
    private final EventService events;
    private final EventAccess access;
    private final JdbcClient jdbc;
    private final Clock clock;
    private final MatPlanner planner;

    MatchControlService(
            MatchRepository matches,
            FightGroupRepository groups,
            MatRepository mats,
            TeamRepository teams,
            TeamMemberRepository teamMembers,
            GroupMemberRepository groupMembers,
            EventService events,
            EventAccess access,
            JdbcClient jdbc,
            Clock clock,
            MatPlanner planner) {
        this.matches = matches;
        this.groups = groups;
        this.mats = mats;
        this.teams = teams;
        this.teamMembers = teamMembers;
        this.groupMembers = groupMembers;
        this.events = events;
        this.access = access;
        this.jdbc = jdbc;
        this.clock = clock;
        this.planner = planner;
    }

    /** Only the club of the event; the superadmin's API checks its own access. */
    public void requireClub(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
    }

    /** An individual group and its pending matches go to another mat; the played ones stay where they were. */
    @Transactional
    public void moveGroup(UUID eventId, UUID groupId, UUID matId, UUID by) {
        var groupMatches = matches.lockByGroupId(groupId);
        var group = group(eventId, groupId);
        events.lock(eventId);
        if (group.getMatId() == null) {
            throw EventException.invalid("A group of teams has no mat: its matches go to the free mats.");
        }
        if (groupMatches.stream().anyMatch(m -> m.getStatus() == Match.Status.IN_PROGRESS)) {
            throw EventException.conflict("MATCH_IN_PROGRESS", "A match of this group is in progress.");
        }
        var mat = refereedMat(eventId, matId);
        group.moveTo(mat.getId());
        groupMatches.stream().filter(m -> m.getStatus() == Match.Status.PENDING).forEach(m -> m.moveTo(mat.getId()));
        log.info("Group {} moved to mat {} by {}", groupId, mat.getNumber(), who(by));
    }

    /**
     * One pending match goes to another mat; the rest of its group stays. A team match leaves the pool and waits on
     * that mat (Raul, 2026-11-13: "mover un combate de un tapiz en cualquier caso"); cancelled, it goes back to it.
     */
    @Transactional
    public void moveMatch(UUID eventId, UUID matchId, UUID matId, UUID by) {
        var match = pending(eventId, matchId);
        events.lock(eventId);
        var mat = refereedMat(eventId, matId);
        match.moveTo(mat.getId());
        log.info("Match {} moved to mat {} by {}", matchId, mat.getNumber(), who(by));
    }

    /**
     * A referee moves one of their mat's pending matches to another mat: one already on it, or a team match of the
     * pool that their mat would take next (its planned queue).
     */
    @Transactional
    public void moveMatchAsReferee(UUID matchId, UUID matId, UUID accountId) {
        var match = matches.findById(matchId).orElseThrow(EventException::notFound);
        var eventId = match.getEventId();
        access.require(eventId, accountId, EventRole.REFEREE);
        var own = mats.findByEventIdAndRefereeAccountIdOrderByNumber(eventId, accountId).stream()
                .map(Mat::getId)
                .toList();
        var mine = match.getMatId() == null
                ? planner.plan(eventId).entrySet().stream()
                        .filter(e -> own.contains(e.getKey()))
                        .anyMatch(e ->
                                e.getValue().stream().anyMatch(p -> p.matchId().equals(matchId)))
                : own.contains(match.getMatId());
        if (!mine) {
            throw EventException.forbidden();
        }
        moveMatch(eventId, matchId, matId, accountId);
    }

    /**
     * The group's pending matches in the order given (all of them, each once). They keep the places they had among
     * the played ones: only who goes in each pending place changes.
     */
    @Transactional
    public void reorder(UUID eventId, UUID groupId, List<UUID> pendingOrder, UUID by) {
        var groupMatches = matches.lockByGroupId(groupId);
        group(eventId, groupId);
        events.lock(eventId);
        var pending = groupMatches.stream()
                .filter(m -> m.getStatus() == Match.Status.PENDING)
                .toList();
        var ids = pending.stream().map(Match::getId).toList();
        if (pendingOrder.size() != ids.size() || !new HashSet<>(pendingOrder).equals(new HashSet<>(ids))) {
            throw EventException.conflict(
                    "ORDER_CHANGED", "The order must name every pending match of the group once: reload and retry.");
        }
        var places = pending.stream().map(Match::getOrderIndex).sorted().toList();
        // Two steps: the order is unique within the group, so the places are freed first.
        jdbc.sql("update fight_match set order_index = -1 - order_index where id in (:ids)")
                .param("ids", ids)
                .update();
        for (int i = 0; i < pendingOrder.size(); i++) {
            jdbc.sql("update fight_match set order_index = :place where id = :id")
                    .param("place", places.get(i))
                    .param("id", pendingOrder.get(i))
                    .update();
        }
        log.info("Group {} reordered by {}", groupId, who(by));
    }

    /**
     * A person goes from one real team to another of the same category. Only while neither team is in a group that
     * has started, and the teams stay of 2 or 3.
     */
    @Transactional
    public void moveTeamMember(UUID eventId, UUID participantId, UUID fromTeamId, UUID toTeamId, UUID by) {
        events.lock(eventId);
        var from = realTeam(eventId, fromTeamId);
        var to = realTeam(eventId, toTeamId);
        if (from.getId().equals(to.getId()) || !from.getCategoryId().equals(to.getCategoryId())) {
            throw EventException.invalid("Both teams must be different and of the same category.");
        }
        var members = teamMembers.findByTeamIdIn(List.of(from.getId(), to.getId()));
        var moving = members.stream()
                .filter(m -> m.getTeamId().equals(from.getId())
                        && m.getParticipantId().equals(participantId))
                .findFirst()
                .orElseThrow(() -> EventException.invalid("That person is not in the first team."));
        var fromSize =
                members.stream().filter(m -> m.getTeamId().equals(from.getId())).count();
        var toSize =
                members.stream().filter(m -> m.getTeamId().equals(to.getId())).count();
        if (fromSize - 1 < TeamService.MIN_SIZE || toSize + 1 > TeamService.MAX_SIZE) {
            throw EventException.conflict(
                    "TEAM_SIZE", "Teams are of " + TeamService.MIN_SIZE + " or " + TeamService.MAX_SIZE + ".");
        }
        var inGroups = groupMembers.findByTeamIdIn(List.of(from.getId(), to.getId()));
        var groupIds = inGroups.stream().map(GroupMember::getGroupId).toList();
        if (anyStarted(groupIds)) {
            throw EventException.conflict(
                    "GROUP_STARTED", "A group of these teams has started: its teams cannot change.");
        }
        // In the new team's group the person must not also fight for another team (a wildcard one).
        var toGroups = inGroups.stream()
                .filter(m -> m.getTeamId().equals(to.getId()))
                .map(GroupMember::getGroupId)
                .toList();
        if (!toGroups.isEmpty() && peopleOfGroups(toGroups).contains(participantId)) {
            throw EventException.conflict("SAME_FIGHTER", "That person already fights in the new team's group.");
        }
        var position = members.stream()
                        .filter(m -> m.getTeamId().equals(to.getId()))
                        .mapToInt(TeamMember::getPosition)
                        .max()
                        .orElse(-1)
                + 1;
        teamMembers.delete(moving);
        teamMembers.flush();
        // A ghost member (fills in without scoring) stays one.
        teamMembers.save(new TeamMember(to, participantId, position, moving.isGhost()));
        log.info("A member moved from team {} to team {} by {}", from.getNumber(), to.getNumber(), who(by));
    }

    /** The referee may start it although someone in it has not had the least rest. Recorded with who and when. */
    @Transactional
    public void waiveRest(UUID eventId, UUID matchId, UUID by) {
        var match = pending(eventId, matchId);
        events.lock(eventId);
        match.waiveRest(by, clock.instant());
        log.info("Rest waived for match {} by {}", matchId, who(by));
    }

    private boolean anyStarted(Collection<UUID> groupIds) {
        return !groupIds.isEmpty()
                && jdbc.sql(
                                "select exists(select 1 from fight_match where group_id in (:ids) and"
                                        + " (status <> 'PENDING' or exists (select 1 from match_event e where e.match_id = fight_match.id)))")
                        .param("ids", groupIds)
                        .query(Boolean.class)
                        .single();
    }

    // Everyone who fights in these groups: the members of their real and wildcard teams.
    private List<UUID> peopleOfGroups(Collection<UUID> groupIds) {
        var teamIds = new ArrayList<UUID>();
        groupMembers.findByGroupIdInOrderByPosition(groupIds).stream()
                .map(GroupMember::getTeamId)
                .filter(id -> id != null)
                .forEach(teamIds::add);
        return teamMembers.findByTeamIdIn(teamIds).stream()
                .map(TeamMember::getParticipantId)
                .toList();
    }

    private FightGroup group(UUID eventId, UUID groupId) {
        return groups.findById(groupId)
                .filter(g -> g.getEventId().equals(eventId))
                .orElseThrow(EventException::notFound);
    }

    private Match pending(UUID eventId, UUID matchId) {
        var match = matches.lockById(matchId)
                .filter(m -> m.getEventId().equals(eventId))
                .orElseThrow(EventException::notFound);
        if (match.getStatus() != Match.Status.PENDING) {
            throw EventException.conflict("MATCH_NOT_PENDING", "Only a match not started yet can change.");
        }
        return match;
    }

    private Mat refereedMat(UUID eventId, UUID matId) {
        var mat = mats.findById(matId)
                .filter(m -> m.getEventId().equals(eventId))
                .orElseThrow(() -> EventException.invalid("That mat is not in this event."));
        if (mat.getRefereeAccountId() == null) {
            throw EventException.conflict("MAT_WITHOUT_REFEREE", "That mat has no referee.");
        }
        return mat;
    }

    private Team realTeam(UUID eventId, UUID teamId) {
        return teams.findById(teamId)
                .filter(t -> t.getEventId().equals(eventId) && !t.isGhost())
                .orElseThrow(EventException::notFound);
    }

    private static String who(UUID by) {
        return by == null ? "the superadmin" : "account " + by;
    }
}
