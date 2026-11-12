package dev.rgal.brackety.ranking;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventOrganizationRepository;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.grouping.Competitor;
import dev.rgal.brackety.grouping.CompetitorDirectory;
import dev.rgal.brackety.grouping.GroupMember;
import dev.rgal.brackety.grouping.GroupMemberRepository;
import dev.rgal.brackety.grouping.Match;
import dev.rgal.brackety.grouping.MatchRepository;
import dev.rgal.brackety.participant.ParticipantRepository;
import dev.rgal.brackety.participant.ParticipantService;
import dev.rgal.brackety.ranking.dto.StandingRow;
import dev.rgal.brackety.scoreboard.Side;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Global score of the phase: attendance plus what each participant scores in finished matches. */
@Service
class StandingsService {

    private final ParticipantRepository participants;
    private final CompetitorDirectory directory;
    private final EventCategoryRepository categories;
    private final EventOrganizationRepository organizations;
    private final GroupMemberRepository members;
    private final MatchRepository matches;
    private final EventService events;
    private final EventAccess access;

    StandingsService(
            ParticipantRepository participants,
            CompetitorDirectory directory,
            EventCategoryRepository categories,
            EventOrganizationRepository organizations,
            GroupMemberRepository members,
            MatchRepository matches,
            EventService events,
            EventAccess access) {
        this.participants = participants;
        this.directory = directory;
        this.categories = categories;
        this.organizations = organizations;
        this.members = members;
        this.matches = matches;
        this.events = events;
        this.access = access;
    }

    @Transactional(readOnly = true)
    List<StandingRow> standings(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        return rows(events.get(eventId));
    }

    /**
     * Best total first. Positions count within each category (as the league's): a podium is per category,
     * a place among every age says nothing. Equal totals share the position and go by name. No access check:
     * callers do it.
     */
    List<StandingRow> rows(Event event) {
        var eventId = event.getId();
        var eventCategories = categories.findByEventIdOrderByMinAge(eventId);
        var organizationNames = ParticipantService.organizationNames(organizations, eventId);
        var competitors = directory.of(eventId);
        var teamNumbers = directory.teamNumbers(eventId);
        var eventMembers = members.findByEventId(eventId);
        var attending = competitors.participants(eventMembers.stream()
                .filter(m -> !m.isGhost())
                .map(GroupMember::getCompetitorId)
                .toArray(UUID[]::new));
        var ghosts = ghostsByGroup(eventMembers);
        var points = new HashMap<UUID, Integer>();
        var fought = new HashMap<UUID, Integer>();
        for (var m : matches.findByEventId(eventId)) {
            if (m.getStatus() != Match.Status.FINISHED) {
                continue;
            }
            count(m, competitors.get(m.getRedId()), Side.RED, m.getRedScore(), ghosts, points, fought);
            count(m, competitors.get(m.getBlueId()), Side.BLUE, m.getBlueScore(), ghosts, points, fought);
        }
        var rows = participants.findByEventIdOrderByFirstNameAscLastNameAsc(eventId).stream()
                .map(p -> {
                    var age = event.ageOf(p.getBirthDate());
                    var category = p.categoryIn(event, eventCategories);
                    var attendance = attending.contains(p.getId()) ? event.getAttendancePoints() : 0;
                    var matchPoints = points.getOrDefault(p.getId(), 0);
                    return new StandingRow(
                            0,
                            p.getId(),
                            p.getFirstName(),
                            p.getLastName(),
                            age,
                            category.map(EventCategory::getId).orElse(null),
                            category.map(EventCategory::getName).orElse(null),
                            attendance,
                            matchPoints,
                            attendance + matchPoints,
                            fought.getOrDefault(p.getId(), 0),
                            teamNumbers.get(p.getId()),
                            p.getPersonId(),
                            organizationNames.get(p.getOrganizationId()));
                })
                .sorted(Comparator.comparingInt(StandingRow::total).reversed())
                .toList();
        var ranked = new ArrayList<StandingRow>();
        // Those without a category rank among themselves.
        var lastInCategory = new HashMap<Optional<UUID>, StandingRow>();
        var seenInCategory = new HashMap<Optional<UUID>, Integer>();
        for (var row : rows) {
            var category = Optional.ofNullable(row.categoryId());
            var seen = seenInCategory.merge(category, 1, Integer::sum);
            var previous = lastInCategory.get(category);
            var tied = previous != null && previous.total() == row.total();
            var placed = row.withPosition(tied ? previous.position() : seen);
            lastInCategory.put(category, placed);
            ranked.add(placed);
        }
        return ranked;
    }

    @Transactional(readOnly = true)
    String standingsCsv(UUID eventId, UUID accountId) {
        var rows = standings(eventId, accountId).stream()
                .map(r -> Arrays.asList(
                        r.position(),
                        r.firstName(),
                        r.lastName(),
                        r.age(),
                        r.organizationName(),
                        r.categoryName(),
                        r.teamNumber() == null ? null : "Equipo " + r.teamNumber(),
                        r.attendancePoints(),
                        r.matchPoints(),
                        r.total(),
                        r.matches()))
                .toList();
        return Csv.of(
                List.of(
                        "Posición",
                        "Nombre",
                        "Apellidos",
                        "Edad el día del evento",
                        "Club",
                        "Categoría",
                        "Equipo",
                        "Puntos de asistencia",
                        "Puntos en combates",
                        "Total",
                        "Combates disputados"),
                rows);
    }

    /** Every member of a team gets the team's points. */
    private static void count(
            Match m,
            Competitor fighter,
            Side side,
            int score,
            Map<UUID, UUID> ghosts,
            Map<UUID, Integer> points,
            Map<UUID, Integer> fought) {
        if (fighter.id().equals(ghosts.get(m.getGroupId()))) {
            return;
        }
        for (var participant : fighter.participantIds()) {
            fought.merge(participant, 1, Integer::sum);
            if (!side.name().equals(m.getDisqualifiedSide())) {
                points.merge(participant, score, Integer::sum);
            }
        }
    }

    static Map<UUID, UUID> ghostsByGroup(List<GroupMember> eventMembers) {
        return eventMembers.stream()
                .filter(GroupMember::isGhost)
                .collect(Collectors.toMap(GroupMember::getGroupId, GroupMember::getCompetitorId));
    }
}
