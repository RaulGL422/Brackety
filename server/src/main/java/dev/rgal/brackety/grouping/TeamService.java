package dev.rgal.brackety.grouping;

import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.grouping.dto.CreateTeamRequest;
import dev.rgal.brackety.grouping.dto.TeamResponse;
import dev.rgal.brackety.grouping.dto.TeamResponse.Member;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.time.Clock;
import java.util.HashSet;
import java.util.List;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Teams of a team category ("Equipo N"), made by the grouper before grouping them. */
@Service
class TeamService {

    private final TeamRepository teams;
    private final TeamMemberRepository teamMembers;
    private final GroupMemberRepository groupMembers;
    private final FightGroupRepository groups;
    private final ParticipantRepository participants;
    private final MatRepository mats;
    private final CategoryRoster roster;
    private final EventService events;
    private final EventAccess access;
    private final Clock clock;

    TeamService(
            TeamRepository teams,
            TeamMemberRepository teamMembers,
            GroupMemberRepository groupMembers,
            FightGroupRepository groups,
            ParticipantRepository participants,
            MatRepository mats,
            CategoryRoster roster,
            EventService events,
            EventAccess access,
            Clock clock) {
        this.teams = teams;
        this.teamMembers = teamMembers;
        this.groupMembers = groupMembers;
        this.groups = groups;
        this.participants = participants;
        this.mats = mats;
        this.roster = roster;
        this.events = events;
        this.access = access;
        this.clock = clock;
    }

    /** The category's real teams by number, with their group once they have one. */
    @Transactional(readOnly = true)
    List<TeamResponse> list(UUID eventId, UUID categoryId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB, EventRole.GROUPER);
        roster.category(eventId, categoryId);
        var categoryTeams = teams.findByCategoryIdAndGhostFalseOrderByNumber(categoryId);
        var people = participants.findByEventIdOrderByFirstNameAscLastNameAsc(eventId).stream()
                .collect(Collectors.toMap(Participant::getId, Function.identity()));
        var membersByTeam =
                teamMembers.findByEventId(eventId).stream().collect(Collectors.groupingBy(TeamMember::getTeamId));
        var groupByTeam = groupMembers
                .findByTeamIdIn(categoryTeams.stream().map(Team::getId).toList())
                .stream()
                .collect(Collectors.toMap(GroupMember::getTeamId, GroupMember::getGroupId));
        var groupById = groups.findByEventId(eventId).stream()
                .collect(Collectors.toMap(FightGroup::getId, Function.identity()));
        var matNumbers =
                mats.findByEventIdOrderByNumber(eventId).stream().collect(Collectors.toMap(Mat::getId, Mat::getNumber));
        var started = new HashSet<>(groups.startedIds(eventId));
        return categoryTeams.stream()
                .map(t -> {
                    var group = groupById.get(groupByTeam.get(t.getId()));
                    return new TeamResponse(
                            t.getId(),
                            t.getNumber(),
                            membersByTeam.getOrDefault(t.getId(), List.of()).stream()
                                    .map(m -> people.get(m.getParticipantId()))
                                    .map(p -> new Member(p.getId(), p.getFirstName(), p.getLastName()))
                                    .toList(),
                            group == null ? null : group.getNumber(),
                            group == null ? null : matNumbers.get(group.getMatId()),
                            group == null ? null : group.getId(),
                            group != null && started.contains(group.getId()));
                })
                .toList();
    }

    @Transactional
    TeamResponse create(UUID eventId, UUID categoryId, UUID accountId, CreateTeamRequest request) {
        access.require(eventId, accountId, EventRole.CLUB, EventRole.GROUPER);
        var event = events.lock(eventId);
        var category = roster.category(eventId, categoryId);
        if (!category.isTeam()) {
            throw EventException.invalid("This category is not by teams.");
        }
        var ids = request.participantIds();
        if (ids.size() != category.getTeamSize() || new HashSet<>(ids).size() != ids.size()) {
            throw EventException.invalid("A team is " + category.getTeamSize() + " different participants.");
        }
        roster.requireAllIn(event, category, ids);
        roster.requireFree(ids);
        var team = save(eventId, categoryId, false, accountId, ids);
        return list(eventId, categoryId, accountId).stream()
                .filter(t -> t.id().equals(team.getId()))
                .findFirst()
                .orElseThrow();
    }

    /** Undoes a team made by mistake; once in a group it stays. */
    @Transactional
    void delete(UUID eventId, UUID teamId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB, EventRole.GROUPER);
        events.lock(eventId);
        var team = teams.findById(teamId)
                .filter(t -> t.getEventId().equals(eventId) && !t.isGhost())
                .orElseThrow(EventException::notFound);
        if (!groupMembers.findByTeamIdIn(List.of(teamId)).isEmpty()) {
            throw EventException.conflict("A team in a group cannot be removed.");
        }
        teams.delete(team);
    }

    /** Also used for the ghost team of a group; the caller holds the event lock. */
    Team save(UUID eventId, UUID categoryId, boolean ghost, UUID accountId, List<UUID> participantIds) {
        var team = teams.save(
                new Team(eventId, categoryId, teams.maxNumber(eventId) + 1, ghost, accountId, clock.instant()));
        for (int i = 0; i < participantIds.size(); i++) {
            teamMembers.save(new TeamMember(team, participantIds.get(i), i));
        }
        return team;
    }
}
