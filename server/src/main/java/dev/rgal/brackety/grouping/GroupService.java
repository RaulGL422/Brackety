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
import dev.rgal.brackety.grouping.dto.CategoryParticipant;
import dev.rgal.brackety.grouping.dto.CategorySummary;
import dev.rgal.brackety.grouping.dto.CreateGroupsRequest;
import dev.rgal.brackety.grouping.dto.CreateGroupsRequest.GroupRequest;
import dev.rgal.brackety.grouping.dto.CreateGroupsResponse;
import dev.rgal.brackety.participant.Participant;
import java.time.Clock;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class GroupService {

    private final FightGroupRepository groups;
    private final GroupMemberRepository members;
    private final MatchRepository matches;
    private final TeamRepository teams;
    private final TeamMemberRepository teamMembers;
    private final TeamService teamService;
    private final EventCategoryRepository categories;
    private final MatRepository mats;
    private final CategoryRoster roster;
    private final CompetitorDirectory directory;
    private final EventService events;
    private final EventAccess access;
    private final MatSchedule schedule;
    private final CompetitionCleanup cleanup;
    private final Clock clock;
    private final StaffNames staffNames;

    GroupService(
            FightGroupRepository groups,
            GroupMemberRepository members,
            MatchRepository matches,
            TeamRepository teams,
            TeamMemberRepository teamMembers,
            TeamService teamService,
            EventCategoryRepository categories,
            MatRepository mats,
            CategoryRoster roster,
            CompetitorDirectory directory,
            EventService events,
            EventAccess access,
            MatSchedule schedule,
            CompetitionCleanup cleanup,
            Clock clock,
            StaffNames staffNames) {
        this.groups = groups;
        this.members = members;
        this.matches = matches;
        this.teams = teams;
        this.teamMembers = teamMembers;
        this.teamService = teamService;
        this.categories = categories;
        this.mats = mats;
        this.roster = roster;
        this.directory = directory;
        this.events = events;
        this.access = access;
        this.schedule = schedule;
        this.cleanup = cleanup;
        this.clock = clock;
        this.staffNames = staffNames;
    }

    /** Categories with participants, youngest first. */
    @Transactional(readOnly = true)
    List<CategorySummary> categories(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB, EventRole.GROUPER);
        var event = events.get(eventId);
        var grouped = roster.groupedIds(eventId);
        var teamNumbers = directory.teamNumbers(eventId);
        var realTeams = teams.findByEventId(eventId).stream()
                .filter(t -> !t.isGhost())
                .collect(Collectors.groupingBy(Team::getCategoryId, Collectors.counting()));
        return categories.findByEventIdOrderByMinAge(eventId).stream()
                .map(c -> {
                    var ids = roster.inCategory(event, c).stream()
                            .map(Participant::getId)
                            .toList();
                    return new CategorySummary(
                            c.getId(),
                            c.getName(),
                            c.getMinAge(),
                            c.getMaxAge(),
                            ids.size(),
                            (int) ids.stream().filter(grouped::containsKey).count(),
                            c.getFormat(),
                            c.getTeamSize(),
                            (int) ids.stream().filter(teamNumbers::containsKey).count(),
                            realTeams.getOrDefault(c.getId(), 0L).intValue());
                })
                .filter(c -> c.participants() > 0)
                .toList();
    }

    /** A category's participants by name; those already in a group or team say which one and where. */
    @Transactional(readOnly = true)
    List<CategoryParticipant> categoryParticipants(UUID eventId, UUID categoryId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB, EventRole.GROUPER);
        var event = events.get(eventId);
        var category = roster.category(eventId, categoryId);
        var grouped = roster.groupedIds(eventId);
        var teamNumbers = directory.teamNumbers(eventId);
        var matNumbers =
                mats.findByEventIdOrderByNumber(eventId).stream().collect(Collectors.toMap(Mat::getId, Mat::getNumber));
        var started = new HashSet<>(groups.startedIds(eventId));
        var labels = staffNames.labels(eventId);
        return roster.inCategory(event, category).stream()
                .map(p -> {
                    var group = grouped.get(p.getId());
                    return new CategoryParticipant(
                            p.getId(),
                            p.getFirstName(),
                            p.getLastName(),
                            p.getHeightCm(),
                            event.ageOf(p.getBirthDate()),
                            group == null ? null : group.getNumber(),
                            group == null ? null : matNumbers.get(group.getMatId()),
                            teamNumbers.get(p.getId()),
                            group == null ? null : group.getId(),
                            group != null && started.contains(group.getId()),
                            group == null ? null : labels.get(group.getCreatedBy()));
                })
                .toList();
    }

    @Transactional
    CreateGroupsResponse create(UUID eventId, UUID accountId, CreateGroupsRequest request) {
        access.require(eventId, accountId, EventRole.CLUB, EventRole.GROUPER);
        var event = events.lock(eventId);
        if (request.groups().size() > event.getMaxGroupsPerMat()) {
            throw EventException.invalid("At most " + event.getMaxGroupsPerMat() + " groups go to a mat at once.");
        }
        var category = roster.category(eventId, request.categoryId());
        checkParticipantGroups(event, category, request.groups());
        checkTeamGroups(event, category, request.groups());
        var mat = request.matId() == null
                ? schedule.soonestFree(event, clock.instant())
                        .orElseThrow(() -> EventException.conflict("No mat has a referee yet."))
                : chosenMat(event, request.matId());
        var number = groups.maxNumber(eventId);
        var numbers = new ArrayList<Integer>();
        var ids = new ArrayList<UUID>();
        for (var group : request.groups()) {
            number++;
            ids.add(save(event, category, mat, number, accountId, group));
            numbers.add(number);
        }
        return new CreateGroupsResponse(mat.getId(), mat.getNumber(), numbers, ids);
    }

    /**
     * The helper takes back a group while none of its matches has started: its members are free again.
     * After that only the superadmin can dissolve it (it wipes the points).
     */
    @Transactional
    void undo(UUID eventId, UUID groupId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB, EventRole.GROUPER);
        // Matches first, then the event: the same order as a match's first start, which locks both.
        var groupMatches = matches.lockByGroupId(groupId);
        var group = groups.findById(groupId)
                .filter(g -> g.getEventId().equals(eventId))
                .orElseThrow(EventException::notFound);
        events.lock(eventId);
        if (groupMatches.stream().anyMatch(m -> m.getStatus() != Match.Status.PENDING)) {
            throw EventException.conflict(
                    "GROUP_STARTED", "A match of this group has started: only the superadmin can undo it now.");
        }
        cleanup.dissolveGroup(group.getId());
    }

    private Mat chosenMat(Event event, UUID matId) {
        var mat = mats.findById(matId)
                .filter(m -> m.getEventId().equals(event.getId()))
                .orElseThrow(() -> EventException.invalid("That mat is not in this event."));
        if (mat.getRefereeAccountId() == null) {
            throw EventException.conflict("That mat has no referee yet.");
        }
        return mat;
    }

    // Also in a team category: the "individual group" for those left without a team.
    private void checkParticipantGroups(Event event, EventCategory category, List<GroupRequest> requested) {
        var real = new ArrayList<UUID>();
        var involved = new HashSet<UUID>();
        for (var group : requested.stream().filter(g -> !g.isOfTeams()).toList()) {
            var ids = group.participantIds() == null ? List.<UUID>of() : group.participantIds();
            checkShape(ids, group.ghostId() != null, "A group is 4 participants, or 3 and a ghost.");
            if (ids.contains(group.ghostId())) {
                throw EventException.invalid("A participant appears twice in a group.");
            }
            real.addAll(ids);
            involved.addAll(ids);
            if (group.ghostId() != null) {
                involved.add(group.ghostId());
            }
        }
        if (real.isEmpty()) {
            return;
        }
        if (new HashSet<>(real).size() != real.size()) {
            throw EventException.invalid("A participant can only be in one of the new groups.");
        }
        roster.requireAllIn(event, category, involved);
        roster.requireFree(real);
    }

    private void checkTeamGroups(Event event, EventCategory category, List<GroupRequest> requested) {
        var teamRequests = requested.stream().filter(GroupRequest::isOfTeams).toList();
        if (teamRequests.isEmpty()) {
            return;
        }
        if (!category.isTeam()) {
            throw EventException.invalid("This category is not by teams.");
        }
        var allTeams = new ArrayList<UUID>();
        var membersByTeam = teamMembers.findByEventId(event.getId()).stream()
                .collect(Collectors.groupingBy(
                        TeamMember::getTeamId, Collectors.mapping(TeamMember::getParticipantId, Collectors.toSet())));
        for (var group : teamRequests) {
            var ghostTeam = group.ghostTeam() == null ? List.<UUID>of() : group.ghostTeam();
            checkShape(group.teamIds(), !ghostTeam.isEmpty(), "A group is 4 teams, or 3 and a ghost team.");
            allTeams.addAll(group.teamIds());
            if (ghostTeam.isEmpty()) {
                continue;
            }
            if (ghostTeam.size() != category.getTeamSize() || new HashSet<>(ghostTeam).size() != ghostTeam.size()) {
                throw EventException.invalid("A ghost team is " + category.getTeamSize() + " different participants.");
            }
            roster.requireAllIn(event, category, ghostTeam);
            var ownMembers = group.teamIds().stream()
                    .flatMap(t -> membersByTeam.getOrDefault(t, Set.of()).stream())
                    .collect(Collectors.toSet());
            if (ghostTeam.stream().anyMatch(ownMembers::contains)) {
                throw EventException.invalid("A ghost team cannot use the group's own fighters.");
            }
        }
        if (new HashSet<>(allTeams).size() != allTeams.size()) {
            throw EventException.invalid("A team can only be in one of the new groups.");
        }
        var found = teams.findAllById(allTeams);
        if (found.size() != allTeams.size()
                || !found.stream().allMatch(t -> t.getCategoryId().equals(category.getId()) && !t.isGhost())) {
            throw EventException.invalid("Every team must be from this category.");
        }
        if (!members.findByTeamIdIn(allTeams).isEmpty()) {
            throw EventException.conflict("A team is already in a group.");
        }
    }

    private static void checkShape(List<UUID> ids, boolean withGhost, String message) {
        var expected = withGhost ? RoundRobin.GROUP_SIZE - 1 : RoundRobin.GROUP_SIZE;
        if (ids.size() != expected) {
            throw EventException.invalid(message);
        }
        if (new HashSet<>(ids).size() != ids.size()) {
            throw EventException.invalid("A competitor appears twice in a group.");
        }
    }

    private UUID save(Event event, EventCategory category, Mat mat, int number, UUID accountId, GroupRequest request) {
        var group = groups.save(
                new FightGroup(event.getId(), category.getId(), mat.getId(), number, accountId, clock.instant()));
        var ofTeams = request.isOfTeams();
        var order = new ArrayList<>(ofTeams ? request.teamIds() : request.participantIds());
        for (int i = 0; i < order.size(); i++) {
            members.save(new GroupMember(group.getId(), order.get(i), ofTeams, i, false));
        }
        var ghost = ofTeams ? ghostTeam(event, category, accountId, request) : request.ghostId();
        if (ghost != null) {
            members.save(new GroupMember(group.getId(), ghost, ofTeams, order.size(), true));
            order.add(ghost);
        }
        var pairs = RoundRobin.pairs();
        for (int i = 0; i < pairs.size(); i++) {
            var pair = pairs.get(i);
            matches.save(new Match(
                    event.getId(),
                    group.getId(),
                    mat.getId(),
                    i,
                    order.get(pair.red()),
                    order.get(pair.blue()),
                    ofTeams));
        }
        return group.getId();
    }

    private UUID ghostTeam(Event event, EventCategory category, UUID accountId, GroupRequest request) {
        if (request.ghostTeam() == null || request.ghostTeam().isEmpty()) {
            return null;
        }
        return teamService
                .save(event.getId(), category.getId(), true, accountId, request.ghostTeam())
                .getId();
    }
}
