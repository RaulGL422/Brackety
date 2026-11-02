package dev.rgal.brackety.grouping;

import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

@Component
public class CompetitorDirectory {

    private final ParticipantRepository participants;
    private final TeamRepository teams;
    private final TeamMemberRepository teamMembers;

    CompetitorDirectory(ParticipantRepository participants, TeamRepository teams, TeamMemberRepository teamMembers) {
        this.participants = participants;
        this.teams = teams;
        this.teamMembers = teamMembers;
    }

    public Competitors of(UUID eventId) {
        var byId = new HashMap<UUID, Competitor>();
        var people = participants.findByEventIdOrderByFirstNameAscLastNameAsc(eventId).stream()
                .collect(Collectors.toMap(Participant::getId, Function.identity()));
        people.values()
                .forEach(p -> byId.put(
                        p.getId(),
                        new Competitor(p.getId(), fullName(p), null, List.of(p.getId()), List.of(fullName(p)))));
        var membersByTeam = teamMembers.findByEventId(eventId).stream()
                .collect(Collectors.groupingBy(
                        TeamMember::getTeamId, Collectors.mapping(TeamMember::getParticipantId, Collectors.toList())));
        for (var team : teams.findByEventId(eventId)) {
            var ids = membersByTeam.getOrDefault(team.getId(), List.of());
            byId.put(
                    team.getId(),
                    new Competitor(
                            team.getId(),
                            "Equipo " + team.getNumber(),
                            team.getNumber(),
                            ids,
                            ids.stream().map(id -> fullName(people.get(id))).toList()));
        }
        return new Competitors(byId);
    }

    /** Participants in a real team (not a ghost one), with its number. */
    public Map<UUID, Integer> teamNumbers(UUID eventId) {
        var numbers = teams.findByEventId(eventId).stream()
                .filter(t -> !t.isGhost())
                .collect(Collectors.toMap(Team::getId, Team::getNumber));
        return teamMembers.findByEventId(eventId).stream()
                .filter(m -> !m.isGhost())
                .collect(Collectors.toMap(TeamMember::getParticipantId, m -> numbers.get(m.getTeamId())));
    }

    private static String fullName(Participant p) {
        return p.getFirstName() + " " + p.getLastName();
    }
}
