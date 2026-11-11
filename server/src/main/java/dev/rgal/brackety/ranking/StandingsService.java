package dev.rgal.brackety.ranking;

import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.grouping.Competitor;
import dev.rgal.brackety.grouping.CompetitorDirectory;
import dev.rgal.brackety.grouping.Competitors;
import dev.rgal.brackety.grouping.FightGroup;
import dev.rgal.brackety.grouping.FightGroupRepository;
import dev.rgal.brackety.grouping.GroupMember;
import dev.rgal.brackety.grouping.GroupMemberRepository;
import dev.rgal.brackety.grouping.Match;
import dev.rgal.brackety.grouping.MatchRepository;
import dev.rgal.brackety.participant.ParticipantRepository;
import dev.rgal.brackety.ranking.dto.StandingRow;
import dev.rgal.brackety.scoreboard.MatchEvent;
import dev.rgal.brackety.scoreboard.MatchEventRepository;
import dev.rgal.brackety.scoreboard.Side;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Global score of the phase: attendance plus what each participant scores in finished matches. */
@Service
class StandingsService {

    private static final DateTimeFormatter TIME = DateTimeFormatter.ofPattern("HH:mm:ss");

    private final ParticipantRepository participants;
    private final CompetitorDirectory directory;
    private final EventCategoryRepository categories;
    private final FightGroupRepository groups;
    private final GroupMemberRepository members;
    private final MatchRepository matches;
    private final MatchEventRepository matchEvents;
    private final MatRepository mats;
    private final AccountRepository accounts;
    private final EventService events;
    private final EventAccess access;
    private final Clock clock;

    StandingsService(
            ParticipantRepository participants,
            CompetitorDirectory directory,
            EventCategoryRepository categories,
            FightGroupRepository groups,
            GroupMemberRepository members,
            MatchRepository matches,
            MatchEventRepository matchEvents,
            MatRepository mats,
            AccountRepository accounts,
            EventService events,
            EventAccess access,
            Clock clock) {
        this.participants = participants;
        this.directory = directory;
        this.categories = categories;
        this.groups = groups;
        this.members = members;
        this.matches = matches;
        this.matchEvents = matchEvents;
        this.mats = mats;
        this.accounts = accounts;
        this.events = events;
        this.access = access;
        this.clock = clock;
    }

    /** Best total first; equal totals share the position and go by name. */
    @Transactional(readOnly = true)
    List<StandingRow> standings(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        var event = events.get(eventId);
        var eventCategories = categories.findByEventIdOrderByMinAge(eventId);
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
                            teamNumbers.get(p.getId()));
                })
                .sorted(Comparator.comparingInt(StandingRow::total).reversed())
                .toList();
        var ranked = new ArrayList<StandingRow>();
        for (int i = 0; i < rows.size(); i++) {
            var tied = i > 0 && rows.get(i - 1).total() == rows.get(i).total();
            ranked.add(rows.get(i).withPosition(tied ? ranked.get(i - 1).position() : i + 1));
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
                        r.categoryName(),
                        r.teamNumber(),
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
                        "Edad",
                        "Categoría",
                        "Equipo",
                        "Asistencia",
                        "Puntos combates",
                        "Total",
                        "Combates"),
                rows);
    }

    @Transactional(readOnly = true)
    String matchesCsv(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        var names = directory.of(eventId);
        var groupById = groupsById(eventId);
        var matNumbers = matNumbers(eventId);
        var categoryNames = categoryNames(eventId);
        var ghosts = ghostsByGroup(members.findByEventId(eventId));
        var rows = matches.findByEventId(eventId).stream()
                .sorted(Comparator.comparingInt(
                                (Match m) -> groupById.get(m.getGroupId()).getNumber())
                        .thenComparingInt(Match::getOrderIndex))
                .map(m -> {
                    var group = groupById.get(m.getGroupId());
                    return Arrays.asList(
                            matNumbers.get(m.getMatId()),
                            group.getNumber(),
                            categoryNames.get(group.getCategoryId()),
                            m.getOrderIndex() + 1,
                            label(names.get(m.getRedId())),
                            label(names.get(m.getBlueId())),
                            m.getRedScore(),
                            m.getBlueScore(),
                            names.name(ghosts.get(m.getGroupId())),
                            disqualifiedName(m, names),
                            status(m.getStatus()),
                            time(m.getStartedAt()),
                            time(m.getFinishedAt()));
                })
                .toList();
        return Csv.of(
                List.of(
                        "Tapiz",
                        "Grupo",
                        "Categoría",
                        "Combate",
                        "Rojo",
                        "Azul",
                        "Puntos rojo",
                        "Puntos azul",
                        "Fantasma",
                        "Descalificado",
                        "Estado",
                        "Inicio",
                        "Fin"),
                rows);
    }

    /** Every referee action of every match: the timeline the club can review. */
    @Transactional(readOnly = true)
    String timelineCsv(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        var names = directory.of(eventId);
        var groupById = groupsById(eventId);
        var matNumbers = matNumbers(eventId);
        var matchById =
                matches.findByEventId(eventId).stream().collect(Collectors.toMap(Match::getId, Function.identity()));
        var history = matchEvents.findByEventId(eventId);
        var actors = accounts
                .findAllById(history.stream()
                        .map(MatchEvent::getActorAccountId)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toSet()))
                .stream()
                .collect(Collectors.toMap(Account::getId, Account::getEmail));
        Set<UUID> undone = history.stream()
                .map(MatchEvent::getTargetEventId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        var rows = history.stream()
                .map(e -> {
                    var m = matchById.get(e.getMatchId());
                    var side = e.getSide() == null
                            ? null
                            : e.getSide() == Side.RED ? names.name(m.getRedId()) : names.name(m.getBlueId());
                    return Arrays.asList(
                            matNumbers.get(m.getMatId()),
                            groupById.get(m.getGroupId()).getNumber(),
                            m.getOrderIndex() + 1,
                            time(e.getAt()),
                            clockText(e.getClockMs()),
                            e.getType().name(),
                            e.getSide() == null ? null : e.getSide().name(),
                            side,
                            e.getDeltaMs() == null ? e.getReason() : adjustText(e.getDeltaMs()),
                            e.isAutomatic() ? "automático" : actors.get(e.getActorAccountId()),
                            undone.contains(e.getId()) ? "sí" : "");
                })
                .toList();
        return Csv.of(
                List.of(
                        "Tapiz",
                        "Grupo",
                        "Combate",
                        "Hora",
                        "Reloj",
                        "Acción",
                        "Lado",
                        "Luchador",
                        "Motivo",
                        "Usuario",
                        "Deshecho"),
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

    private static Map<UUID, UUID> ghostsByGroup(List<GroupMember> eventMembers) {
        return eventMembers.stream()
                .filter(GroupMember::isGhost)
                .collect(Collectors.toMap(GroupMember::getGroupId, GroupMember::getCompetitorId));
    }

    private Map<UUID, FightGroup> groupsById(UUID eventId) {
        return groups.findByEventId(eventId).stream().collect(Collectors.toMap(FightGroup::getId, Function.identity()));
    }

    private Map<UUID, Integer> matNumbers(UUID eventId) {
        return mats.findByEventIdOrderByNumber(eventId).stream().collect(Collectors.toMap(Mat::getId, Mat::getNumber));
    }

    private Map<UUID, String> categoryNames(UUID eventId) {
        return categories.findByEventIdOrderByMinAge(eventId).stream()
                .collect(Collectors.toMap(EventCategory::getId, EventCategory::getName));
    }

    private static String disqualifiedName(Match m, Competitors names) {
        if (m.getDisqualifiedSide() == null) {
            return null;
        }
        return names.name(m.getDisqualifiedSide().equals(Side.RED.name()) ? m.getRedId() : m.getBlueId());
    }

    /** "Equipo N (names)" for a team, so the sheet says who fought. */
    private static String label(Competitor c) {
        return c.isTeam() ? c.name() + " (" + String.join(", ", c.memberNames()) + ")" : c.name();
    }

    private static String status(Match.Status status) {
        return switch (status) {
            case PENDING -> "pendiente";
            case IN_PROGRESS -> "en curso";
            case FINISHED -> "finalizado";
        };
    }

    private String time(Instant instant) {
        return instant == null ? null : TIME.format(instant.atZone(clock.getZone()));
    }

    // Words, not a sign: a cell starting with + or - would be neutralised for spreadsheets.
    private static String adjustText(long deltaMs) {
        return (deltaMs > 0 ? "añade " : "quita ") + Math.abs(deltaMs) / 1000 + " s";
    }

    private static String clockText(long clockMs) {
        var d = Duration.ofMillis(clockMs);
        return "%d:%02d".formatted(d.toMinutes(), d.toSecondsPart());
    }
}
