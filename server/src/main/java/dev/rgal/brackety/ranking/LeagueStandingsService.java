package dev.rgal.brackety.ranking;

import dev.rgal.brackety.common.Names;
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
import java.time.Clock;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
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
    private static final DateTimeFormatter PDF_TIME = DateTimeFormatter.ofPattern("HH:mm");

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
    private final Clock clock;

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
            MatchSnapshots snapshots,
            Clock clock) {
        this.clock = clock;
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
        var latestPhase = new HashMap<UUID, UUID>();
        var points = new HashMap<UUID, PhasePoints[]>();
        for (int i = 0; i < phases.size(); i++) {
            for (var row : standings.rows(phases.get(i))) {
                latest.put(row.personId(), row);
                latestPhase.put(row.personId(), phases.get(i).getId());
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
                .forEach(e -> rows.addAll(ranked(
                        e.getKey(),
                        e.getValue().stream()
                                .map(r -> unranked(
                                        e.getKey(),
                                        r,
                                        Arrays.asList(points.get(r.personId())),
                                        discipline,
                                        latestPhase.get(r.personId())))
                                .toList(),
                        podium.of(e.getKey()))));
        return new LeagueStandings(
                phases.stream()
                        .map(p -> new LeagueStandings.Phase(p.getId(), p.getPhaseNumber(), p.getName()))
                        .toList(),
                rows);
    }

    // A person with their points phase by phase (null where they did not take part), not yet placed.
    private static Row unranked(
            String category, StandingRow r, List<PhasePoints> phasePoints, Discipline discipline, UUID latestPhase) {
        var total = phasePoints.stream()
                .filter(p -> p != null)
                .mapToInt(PhasePoints::total)
                .sum();
        return new Row(
                category,
                0,
                null,
                r.personId(),
                r.firstName(),
                r.lastName(),
                r.organizationName(),
                phasePoints,
                total,
                discipline.warnings().getOrDefault(r.personId(), 0),
                discipline.disqualifications().getOrDefault(r.personId(), 0),
                latestPhase,
                r.participantId());
    }

    // Most points first, then by name; the same total shares the position and the medal.
    private static List<Row> ranked(String category, List<Row> people, Podium podium) {
        var sorted = people.stream()
                .sorted(Comparator.comparingInt(Row::total)
                        .reversed()
                        .thenComparing(Row::firstName, Names.ORDER)
                        .thenComparing(Row::lastName, Names.ORDER))
                .toList();
        var placed = new ArrayList<Row>();
        for (int i = 0; i < sorted.size(); i++) {
            var r = sorted.get(i);
            var position = i > 0 && sorted.get(i - 1).total() == r.total()
                    ? placed.getLast().position()
                    : i + 1;
            var medal = NO_CATEGORY.equals(category) ? null : podium.medal(position, r.total());
            placed.add(r.placed(position, medal));
        }
        return placed;
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

    /** The league standings to print: each category on its own page. */
    @Transactional(readOnly = true)
    byte[] pdf(UUID eventId, UUID accountId) {
        var result = standings(eventId, accountId);
        var event = eventService.get(eventId);
        var league = leagues.findById(event.getLeagueId()).orElseThrow();
        var heading = league.getName() + " · " + event.getName() + " · " + SheetText.date(event.getEventDate());
        var now = LocalDateTime.now(clock);
        var generated = SheetText.date(now.toLocalDate()) + " a las " + PDF_TIME.format(now);
        return StandingsPdf.of(result, heading, generated);
    }
}
