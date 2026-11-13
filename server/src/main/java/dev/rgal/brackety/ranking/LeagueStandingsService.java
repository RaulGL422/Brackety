package dev.rgal.brackety.ranking;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventRepository;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.grouping.CompetitorDirectory;
import dev.rgal.brackety.grouping.Match;
import dev.rgal.brackety.grouping.MatchRepository;
import dev.rgal.brackety.league.CategoryPodium;
import dev.rgal.brackety.league.CategoryPodiumRepository;
import dev.rgal.brackety.league.LeagueRepository;
import dev.rgal.brackety.league.Podium;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import dev.rgal.brackety.ranking.dto.LeagueStandings;
import dev.rgal.brackety.ranking.dto.LeagueStandings.PhasePoints;
import dev.rgal.brackety.ranking.dto.LeagueStandings.Row;
import dev.rgal.brackety.ranking.dto.StandingRow;
import dev.rgal.brackety.scoreboard.MatchSnapshots;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Points add up across the phases of the league, per person (docs/modulos/liga-fases.md). Each person is ranked in
 * the category of their latest phase; the podium decides the medals (see {@link Podium}).
 */
@Service
class LeagueStandingsService {

    static final String NO_CATEGORY = "Sin categoría";

    private final StandingsService standings;
    private final EventRepository events;
    private final EventService eventService;
    private final EventCategoryRepository categories;
    private final LeagueRepository leagues;
    private final CategoryPodiumRepository podiums;
    private final EventAccess access;
    private final MatchRepository matches;
    private final CompetitorDirectory directory;
    private final ParticipantRepository participants;
    private final MatchSnapshots snapshots;

    LeagueStandingsService(
            StandingsService standings,
            EventRepository events,
            EventService eventService,
            EventCategoryRepository categories,
            LeagueRepository leagues,
            CategoryPodiumRepository podiums,
            EventAccess access,
            MatchRepository matches,
            CompetitorDirectory directory,
            ParticipantRepository participants,
            MatchSnapshots snapshots) {
        this.matches = matches;
        this.directory = directory;
        this.participants = participants;
        this.snapshots = snapshots;
        this.standings = standings;
        this.events = events;
        this.eventService = eventService;
        this.categories = categories;
        this.leagues = leagues;
        this.podiums = podiums;
        this.access = access;
    }

    @Transactional(readOnly = true)
    LeagueStandings standings(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        return of(eventService.get(eventId));
    }

    LeagueStandings of(Event event) {
        var phases = events.findByLeagueIdOrderByPhaseNumber(event.getLeagueId());
        var latest = new HashMap<UUID, StandingRow>();
        var points = new HashMap<UUID, PhasePoints[]>();
        for (int i = 0; i < phases.size(); i++) {
            for (var row : standings.rows(phases.get(i))) {
                latest.put(row.personId(), row);
                points.computeIfAbsent(row.personId(), k -> new PhasePoints[phases.size()])[i] =
                        new PhasePoints(row.attendancePoints(), row.matchPoints());
            }
        }
        var discipline = discipline(phases);
        var podium = podiums(event.getLeagueId());
        var order = categoryOrder(phases);
        var byCategory = latest.values().stream()
                .collect(Collectors.groupingBy(r -> r.categoryName() == null ? NO_CATEGORY : r.categoryName()));
        var rows = new ArrayList<Row>();
        byCategory.entrySet().stream()
                .sorted(Comparator.comparingInt(e -> order.getOrDefault(e.getKey(), Integer.MAX_VALUE)))
                .forEach(e -> {
                    var categoryPodium = podium.of(e.getKey());
                    var people = e.getValue().stream()
                            .map(r -> {
                                var phasePoints = Arrays.asList(points.get(r.personId()));
                                var total = phasePoints.stream()
                                        .filter(p -> p != null)
                                        .mapToInt(PhasePoints::total)
                                        .sum();
                                return new Row(
                                        e.getKey(),
                                        0,
                                        null,
                                        r.personId(),
                                        r.firstName(),
                                        r.lastName(),
                                        r.organizationName(),
                                        phasePoints,
                                        total,
                                        discipline.warnings().getOrDefault(r.personId(), 0),
                                        discipline.disqualifications().getOrDefault(r.personId(), 0));
                            })
                            .sorted(Comparator.comparingInt(Row::total)
                                    .reversed()
                                    .thenComparing(Row::firstName, String.CASE_INSENSITIVE_ORDER)
                                    .thenComparing(Row::lastName, String.CASE_INSENSITIVE_ORDER))
                            .toList();
                    for (int i = 0; i < people.size(); i++) {
                        var r = people.get(i);
                        var position = i > 0 && people.get(i - 1).total() == r.total()
                                ? rows.getLast().position()
                                : i + 1;
                        var medal = NO_CATEGORY.equals(e.getKey()) ? null : categoryPodium.medal(position, r.total());
                        rows.add(new Row(
                                r.categoryName(),
                                position,
                                medal,
                                r.personId(),
                                r.firstName(),
                                r.lastName(),
                                r.organizationName(),
                                r.phases(),
                                r.total(),
                                r.warnings(),
                                r.disqualifications()));
                    }
                });
        return new LeagueStandings(
                phases.stream()
                        .map(p -> new LeagueStandings.Phase(p.getId(), p.getPhaseNumber(), p.getName()))
                        .toList(),
                rows);
    }

    private record Discipline(Map<UUID, Integer> warnings, Map<UUID, Integer> disqualifications) {}

    // Per person, from every started match of every phase: a team's warnings count for each of its members.
    private Discipline discipline(List<Event> phases) {
        var warnings = new HashMap<UUID, Integer>();
        var disqualifications = new HashMap<UUID, Integer>();
        for (var phase : phases) {
            var persons = participants.findByEventIdOrderByFirstNameAscLastNameAsc(phase.getId()).stream()
                    .collect(Collectors.toMap(Participant::getId, Participant::getPersonId));
            var competitors = directory.of(phase.getId());
            for (var m : matches.findByEventId(phase.getId())) {
                if (m.getStatus() == Match.Status.PENDING) {
                    continue;
                }
                var view = snapshots.of(m);
                for (var corner : List.of(view.red(), view.blue())) {
                    var fighter = corner.teamId() != null ? corner.teamId() : corner.participantId();
                    for (var p : competitors.participants(fighter)) {
                        var person = persons.get(p);
                        warnings.merge(person, corner.warnings() + corner.oneHandWarnings(), Integer::sum);
                        disqualifications.merge(person, corner.disqualified() ? 1 : 0, Integer::sum);
                    }
                }
            }
        }
        return new Discipline(warnings, disqualifications);
    }

    /** The league's podium and the categories with their own. */
    record Podiums(Podium league, Map<String, Podium> own) {

        Podium of(String categoryName) {
            return own.getOrDefault(categoryName, league);
        }
    }

    Podiums podiums(UUID leagueId) {
        var league = leagues.findById(leagueId).orElseThrow();
        return new Podiums(
                league.getPodium(),
                podiums.findByLeagueIdOrderByCategoryName(leagueId).stream()
                        .collect(Collectors.toMap(CategoryPodium::getCategoryName, CategoryPodium::getPodium)));
    }

    private Map<String, Integer> categoryOrder(List<Event> phases) {
        var order = new LinkedHashMap<String, Integer>();
        phases.stream()
                .flatMap(p -> categories.findByEventIdOrderByMinAge(p.getId()).stream())
                .sorted(Comparator.comparingInt(EventCategory::getMinAge))
                .forEach(c -> order.putIfAbsent(c.getName(), order.size()));
        return order;
    }

    @Transactional(readOnly = true)
    String csv(UUID eventId, UUID accountId) {
        var result = standings(eventId, accountId);
        var header = new ArrayList<>(List.of("Categoría", "Posición", "Medalla", "Nombre", "Apellidos", "Club"));
        for (var phase : result.phases()) {
            header.add("Fase " + phase.number() + ": asistencia");
            header.add("Fase " + phase.number() + ": puntos en combates");
            header.add("Fase " + phase.number() + ": total");
        }
        header.add("Total liga");
        header.add("Advertencias en la liga");
        header.add("Descalificaciones en la liga");
        var rows = result.rows().stream()
                .map(r -> {
                    var cells = new ArrayList<Object>();
                    cells.add(r.categoryName());
                    // With 0 points nobody has a place yet (the app shows a dash too).
                    cells.add(r.total() > 0 ? r.position() : null);
                    cells.add(SheetText.medal(r.medal()));
                    cells.add(r.firstName());
                    cells.add(r.lastName());
                    cells.add(r.organizationName());
                    for (var p : r.phases()) {
                        cells.add(p == null ? "No inscrito" : p.attendancePoints());
                        cells.add(p == null ? null : p.matchPoints());
                        cells.add(p == null ? null : p.total());
                    }
                    cells.add(r.total());
                    cells.add(r.warnings());
                    cells.add(r.disqualifications());
                    return cells;
                })
                .toList();
        return Csv.of(header, rows);
    }
}
