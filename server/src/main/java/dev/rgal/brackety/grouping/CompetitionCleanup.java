package dev.rgal.brackety.grouping;

import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventService;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** The superadmin undoes groups: their members are back where the helper left them before grouping. */
@Service
public class CompetitionCleanup {

    private final FightGroupRepository groups;
    private final GroupMemberRepository members;
    private final TeamRepository teams;
    private final EventService events;

    CompetitionCleanup(
            FightGroupRepository groups, GroupMemberRepository members, TeamRepository teams, EventService events) {
        this.groups = groups;
        this.members = members;
        this.teams = teams;
        this.events = events;
    }

    /**
     * The group, its matches and their actions go; its members are without a group again. A ghost team
     * exists only for its group, so it goes too. Returns the group's event.
     */
    @Transactional
    public UUID dissolveGroup(UUID groupId) {
        var group = groups.findById(groupId).orElseThrow(EventException::notFound);
        var eventId = group.getEventId();
        // The same lock as creating a group: a group being made at once never sees half of this.
        events.lock(eventId);
        var memberTeams = members.findByGroupIdInOrderByPosition(List.of(groupId)).stream()
                .map(GroupMember::getTeamId)
                .filter(Objects::nonNull)
                .toList();
        var ghostTeams = teams.findAllById(memberTeams).stream()
                .filter(Team::isGhost)
                .map(Team::getId)
                .toList();
        groups.deleteNow(groupId);
        if (!ghostTeams.isEmpty()) {
            teams.deleteAllByIdInBatch(ghostTeams);
        }
        return eventId;
    }

    /**
     * The event as it was before the first group: every group, match and team goes; settings, mats,
     * staff and entries stay. Teams go too (decided by Raul): the helper forms them again.
     */
    @Transactional
    public Cleared clearCompetition(UUID eventId) {
        events.lock(eventId);
        var groupCount = groups.deleteByEvent(eventId);
        var teamCount = teams.deleteByEvent(eventId);
        return new Cleared(groupCount, teamCount);
    }

    /** How many groups and teams went (ghost teams included). */
    public record Cleared(int groups, int teams) {}
}
