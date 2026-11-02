package dev.rgal.brackety.grouping;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/** Who is in which category, and who already competes for real in a team or a group. */
@Component
class CategoryRoster {

    private final EventCategoryRepository categories;
    private final ParticipantRepository participants;
    private final FightGroupRepository groups;
    private final GroupMemberRepository groupMembers;
    private final TeamMemberRepository teamMembers;

    CategoryRoster(
            EventCategoryRepository categories,
            ParticipantRepository participants,
            FightGroupRepository groups,
            GroupMemberRepository groupMembers,
            TeamMemberRepository teamMembers) {
        this.categories = categories;
        this.participants = participants;
        this.groups = groups;
        this.groupMembers = groupMembers;
        this.teamMembers = teamMembers;
    }

    EventCategory category(UUID eventId, UUID categoryId) {
        return categories
                .findById(categoryId)
                .filter(c -> c.getEventId().equals(eventId))
                .orElseThrow(EventException::notFound);
    }

    List<Participant> inCategory(Event event, EventCategory category) {
        var all = categories.findByEventIdOrderByMinAge(event.getId());
        return participants.findByEventIdOrderByFirstNameAscLastNameAsc(event.getId()).stream()
                .filter(p -> isIn(event, category, all, p))
                .toList();
    }

    void requireAllIn(Event event, EventCategory category, Collection<UUID> ids) {
        var unique = new HashSet<>(ids);
        var found = participants.findAllById(unique);
        var all = categories.findByEventIdOrderByMinAge(event.getId());
        if (found.size() != unique.size()
                || !found.stream()
                        .allMatch(p -> p.getEventId().equals(event.getId()) && isIn(event, category, all, p))) {
            throw EventException.invalid("Every participant must be from this event and category.");
        }
    }

    /** A participant competes for real in one place only: a real team or an individual group. */
    void requireFree(Collection<UUID> ids) {
        if (!groupMembers.findByParticipantIdInAndGhostFalse(ids).isEmpty()
                || !teamMembers.findByParticipantIdInAndGhostFalse(ids).isEmpty()) {
            throw EventException.conflict("A participant is already in a group or team.");
        }
    }

    /** Participants competing for real in a group, directly or through their team, with that group. */
    Map<UUID, FightGroup> groupedIds(UUID eventId) {
        var byId = groups.findByEventId(eventId).stream()
                .collect(Collectors.toMap(FightGroup::getId, Function.identity()));
        var membersByTeam = teamMembers.findByEventId(eventId).stream()
                .filter(m -> !m.isGhost())
                .collect(Collectors.groupingBy(
                        TeamMember::getTeamId, Collectors.mapping(TeamMember::getParticipantId, Collectors.toList())));
        var result = new HashMap<UUID, FightGroup>();
        groupMembers.findByEventId(eventId).stream().filter(m -> !m.isGhost()).forEach(m -> {
            var group = byId.get(m.getGroupId());
            if (m.getParticipantId() != null) {
                result.put(m.getParticipantId(), group);
            } else {
                membersByTeam.getOrDefault(m.getTeamId(), List.of()).forEach(p -> result.put(p, group));
            }
        });
        return result;
    }

    private static boolean isIn(Event event, EventCategory category, List<EventCategory> all, Participant participant) {
        return participant
                .categoryIn(event, all)
                .filter(c -> c.getId().equals(category.getId()))
                .isPresent();
    }
}
