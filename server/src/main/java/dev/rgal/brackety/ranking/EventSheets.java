package dev.rgal.brackety.ranking;

import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventOrganizationRepository;
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
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import dev.rgal.brackety.participant.ParticipantService;
import dev.rgal.brackety.scoreboard.MatchEvent;
import dev.rgal.brackety.scoreboard.MatchEventRepository;
import dev.rgal.brackety.scoreboard.Side;
import java.time.Clock;
import java.time.ZoneId;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * The event as sheets for Excel (Spanish headers, readable names, no ids as the only reference): participants,
 * categories, mats, groups, matches and the timeline of every match. Only the club of the event.
 */
@Service
class EventSheets {

    private final ParticipantRepository participants;
    private final CompetitorDirectory directory;
    private final EventCategoryRepository categories;
    private final EventOrganizationRepository organizations;
    private final FightGroupRepository groups;
    private final GroupMemberRepository members;
    private final MatchRepository matches;
    private final MatchEventRepository matchEvents;
    private final MatRepository mats;
    private final AccountRepository accounts;
    private final EventService events;
    private final EventAccess access;
    private final ZoneId zone;

    EventSheets(
            ParticipantRepository participants,
            CompetitorDirectory directory,
            EventCategoryRepository categories,
            EventOrganizationRepository organizations,
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
        this.organizations = organizations;
        this.groups = groups;
        this.members = members;
        this.matches = matches;
        this.matchEvents = matchEvents;
        this.mats = mats;
        this.accounts = accounts;
        this.events = events;
        this.access = access;
        this.zone = clock.getZone();
    }

    /** What is known of the event, loaded once for every sheet. */
    private record Data(
            Event event,
            List<Participant> participants,
            Map<UUID, String> organizationNames,
            List<EventCategory> categories,
            Map<UUID, String> categoryNames,
            Competitors competitors,
            Map<UUID, Integer> teamNumbers,
            Map<UUID, FightGroup> groups,
            List<GroupMember> members,
            List<Match> matches,
            Map<UUID, Integer> matNumbers,
            List<Mat> mats) {

        String clubOf(Competitor c, Map<UUID, Participant> byId) {
            return c.participantIds().stream()
                    .map(id -> organizationNames.get(byId.get(id).getOrganizationId()))
                    .filter(Objects::nonNull)
                    .collect(Collectors.toCollection(LinkedHashSet::new))
                    .stream()
                    .collect(Collectors.joining(", "));
        }

        Map<UUID, Participant> participantsById() {
            return participants.stream().collect(Collectors.toMap(Participant::getId, Function.identity()));
        }
    }

    private Data data(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        var eventCategories = categories.findByEventIdOrderByMinAge(eventId);
        var eventMats = mats.findByEventIdOrderByNumber(eventId);
        return new Data(
                events.get(eventId),
                participants.findByEventIdOrderByFirstNameAscLastNameAsc(eventId),
                ParticipantService.organizationNames(organizations, eventId),
                eventCategories,
                eventCategories.stream().collect(Collectors.toMap(EventCategory::getId, EventCategory::getName)),
                directory.of(eventId),
                directory.teamNumbers(eventId),
                groups.findByEventId(eventId).stream()
                        .collect(Collectors.toMap(FightGroup::getId, Function.identity())),
                members.findByEventId(eventId),
                matches.findByEventId(eventId).stream()
                        .sorted(Comparator.comparing(Match::getMatId).thenComparing(Match::getOrderIndex))
                        .toList(),
                eventMats.stream().collect(Collectors.toMap(Mat::getId, Mat::getNumber)),
                eventMats);
    }

    @Transactional(readOnly = true)
    String participantsCsv(UUID eventId, UUID accountId) {
        var d = data(eventId, accountId);
        var groupOf = new HashMap<UUID, FightGroup>();
        var teamGroups = new HashMap<UUID, FightGroup>();
        for (var m : d.members()) {
            if (m.isGhost()) {
                continue;
            }
            if (m.getTeamId() != null) {
                teamGroups.put(m.getTeamId(), d.groups().get(m.getGroupId()));
            } else {
                groupOf.put(m.getParticipantId(), d.groups().get(m.getGroupId()));
            }
        }
        var teamIdByNumber = new HashMap<Integer, UUID>();
        for (var m : d.members()) {
            var c = m.getTeamId() == null ? null : d.competitors().get(m.getTeamId());
            if (c != null) {
                teamIdByNumber.put(c.teamNumber(), c.id());
            }
        }
        var rows = d.participants().stream()
                .map(p -> {
                    var age = d.event().ageOf(p.getBirthDate());
                    var category = p.categoryIn(d.event(), d.categories());
                    var team = d.teamNumbers().get(p.getId());
                    var group = groupOf.get(p.getId());
                    if (group == null && team != null) {
                        group = teamGroups.get(teamIdByNumber.get(team));
                    }
                    var minor = age < ParticipantService.ADULT_AGE;
                    return Arrays.asList(
                            p.getFirstName(),
                            p.getLastName(),
                            SheetText.date(p.getBirthDate()),
                            age,
                            p.getHeightCm(),
                            d.organizationNames().get(p.getOrganizationId()),
                            category.map(EventCategory::getName).orElse("Sin categoría"),
                            p.getCategoryId() == null ? "Por edad" : "Elegida a mano",
                            minor ? (p.hasGuardianConsent() ? "Sí" : "Falta") : "No hace falta (adulto)",
                            team == null ? null : "Equipo " + team,
                            group == null ? null : group.getNumber(),
                            group == null ? null : d.matNumbers().get(group.getMatId()),
                            p.getPersonId());
                })
                .toList();
        return Csv.of(
                List.of(
                        "Nombre",
                        "Apellidos",
                        "Fecha de nacimiento",
                        "Edad el día del evento",
                        "Estatura (cm)",
                        "Club",
                        "Categoría",
                        "Cómo se asignó la categoría",
                        "Consentimiento del tutor",
                        "Equipo",
                        "Grupo",
                        "Tapiz",
                        "Id de la persona (igual en todas las fases)"),
                rows);
    }

    @Transactional(readOnly = true)
    String categoriesCsv(UUID eventId, UUID accountId, LeagueStandingsService.Podiums podiums) {
        var d = data(eventId, accountId);
        var entered = new HashMap<UUID, Integer>();
        for (var p : d.participants()) {
            p.categoryIn(d.event(), d.categories()).ifPresent(c -> entered.merge(c.getId(), 1, Integer::sum));
        }
        var groupCount = d.groups().values().stream()
                .collect(Collectors.groupingBy(FightGroup::getCategoryId, Collectors.counting()));
        var rows = d.categories().stream()
                .map(c -> {
                    var podium = podiums.of(c.getName());
                    return Arrays.<Object>asList(
                            c.getName(),
                            c.getMinAge(),
                            c.getMaxAge(),
                            c.getFormat() == EventCategory.Format.TEAM ? "Por equipos" : "Individual",
                            c.getTeamSize(),
                            c.getGroupSize(),
                            entered.getOrDefault(c.getId(), 0),
                            groupCount.getOrDefault(c.getId(), 0L),
                            podium.firsts(),
                            podium.seconds(),
                            podium.thirds());
                })
                .toList();
        return Csv.of(
                List.of(
                        "Categoría",
                        "Edad mínima",
                        "Edad máxima",
                        "Formato",
                        "Alumnos por equipo",
                        "Por grupo (alumnos o equipos)",
                        "Inscritos",
                        "Grupos",
                        "Podio: primeros",
                        "Podio: segundos",
                        "Podio: terceros"),
                rows);
    }

    @Transactional(readOnly = true)
    String matsCsv(UUID eventId, UUID accountId) {
        var d = data(eventId, accountId);
        var referees = usernames(d.mats().stream()
                .map(Mat::getRefereeAccountId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet()));
        var rows = d.mats().stream()
                .map(mat -> {
                    var mine = d.matches().stream()
                            .filter(m -> m.getMatId().equals(mat.getId()))
                            .toList();
                    return Arrays.<Object>asList(
                            mat.getNumber(),
                            referees.getOrDefault(mat.getRefereeAccountId(), "Sin árbitro"),
                            d.groups().values().stream()
                                    .filter(g -> g.getMatId().equals(mat.getId()))
                                    .count(),
                            mine.size(),
                            mine.stream()
                                    .filter(m -> m.getStatus() == Match.Status.FINISHED)
                                    .count());
                })
                .toList();
        return Csv.of(List.of("Tapiz", "Árbitro (usuario)", "Grupos", "Combates", "Combates terminados"), rows);
    }

    /** One row per group member, in the order of the group. */
    @Transactional(readOnly = true)
    String groupsCsv(UUID eventId, UUID accountId) {
        var d = data(eventId, accountId);
        var byId = d.participantsById();
        var creators = usernames(d.groups().values().stream()
                .map(FightGroup::getCreatedBy)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet()));
        var rows = d.members().stream()
                .sorted(Comparator.comparingInt((GroupMember m) ->
                                d.groups().get(m.getGroupId()).getNumber())
                        .thenComparingInt(GroupMember::getPosition))
                .map(m -> {
                    var g = d.groups().get(m.getGroupId());
                    var c = d.competitors().get(m.getCompetitorId());
                    return Arrays.<Object>asList(
                            g.getNumber(),
                            d.categoryNames().get(g.getCategoryId()),
                            d.matNumbers().get(g.getMatId()),
                            SheetText.date(g.getCreatedAt(), zone) + " " + SheetText.time(g.getCreatedAt(), zone),
                            creators.get(g.getCreatedBy()),
                            m.getPosition() + 1,
                            c.name(),
                            c.isTeam() ? String.join(", ", c.memberNames()) : null,
                            d.clubOf(c, byId),
                            m.isGhost() ? "Sí (combate, no puntúa)" : "No");
                })
                .toList();
        return Csv.of(
                List.of(
                        "Grupo",
                        "Categoría",
                        "Tapiz",
                        "Creado",
                        "Creado por",
                        "Orden en el grupo",
                        "Alumno o equipo",
                        "Miembros del equipo",
                        "Club",
                        "Fantasma"),
                rows);
    }

    @Transactional(readOnly = true)
    String matchesCsv(UUID eventId, UUID accountId) {
        var d = data(eventId, accountId);
        var byId = d.participantsById();
        var ghosts = StandingsService.ghostsByGroup(d.members());
        var rows = d.matches().stream()
                .sorted(Comparator.comparingInt(
                                (Match m) -> d.groups().get(m.getGroupId()).getNumber())
                        .thenComparingInt(Match::getOrderIndex))
                .map(m -> {
                    var group = d.groups().get(m.getGroupId());
                    var red = d.competitors().get(m.getRedId());
                    var blue = d.competitors().get(m.getBlueId());
                    var ghost = ghosts.get(m.getGroupId());
                    return Arrays.<Object>asList(
                            group.getNumber(),
                            d.categoryNames().get(group.getCategoryId()),
                            d.matNumbers().get(m.getMatId()),
                            m.getOrderIndex() + 1,
                            SheetText.label(red),
                            d.clubOf(red, byId),
                            SheetText.label(blue),
                            d.clubOf(blue, byId),
                            m.getRedScore(),
                            m.getBlueScore(),
                            winner(m, red, blue),
                            endReason(m, d.event().getPointsLimit(), red, blue),
                            SheetText.status(m.getStatus()),
                            ghost == null ? null : d.competitors().name(ghost),
                            SheetText.date(m.getStartedAt(), zone),
                            SheetText.time(m.getStartedAt(), zone),
                            SheetText.time(m.getFinishedAt(), zone),
                            m.getStartedAt() == null ? null : SheetText.duration(m.getElapsedMs()));
                })
                .toList();
        return Csv.of(
                List.of(
                        "Grupo",
                        "Categoría",
                        "Tapiz",
                        "Combate nº (en el grupo)",
                        "Rojo",
                        "Club rojo",
                        "Azul",
                        "Club azul",
                        "Puntos rojo",
                        "Puntos azul",
                        "Ganador",
                        "Cómo acabó",
                        "Estado",
                        "Fantasma del grupo (no puntúa)",
                        "Fecha",
                        "Hora de inicio",
                        "Hora de fin",
                        "Tiempo de combate (m:ss)"),
                rows);
    }

    /** Every referee action of every match, in order: the timeline the club can review. */
    @Transactional(readOnly = true)
    String timelineCsv(UUID eventId, UUID accountId) {
        var d = data(eventId, accountId);
        var matchById = d.matches().stream().collect(Collectors.toMap(Match::getId, Function.identity()));
        var history = matchEvents.findByEventId(eventId);
        var actors = usernames(history.stream()
                .map(MatchEvent::getActorAccountId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet()));
        var positions = new HashMap<UUID, Integer>();
        var counters = new HashMap<UUID, Integer>();
        for (var e : history) {
            positions.put(e.getId(), counters.merge(e.getMatchId(), 1, Integer::sum));
        }
        Set<UUID> undone = history.stream()
                .map(MatchEvent::getTargetEventId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        var rows = history.stream()
                .sorted(Comparator.comparingInt((MatchEvent e) -> d.groups()
                                .get(matchById.get(e.getMatchId()).getGroupId())
                                .getNumber())
                        .thenComparingInt(e -> matchById.get(e.getMatchId()).getOrderIndex())
                        .thenComparingInt(e -> positions.get(e.getId())))
                .map(e -> {
                    var m = matchById.get(e.getMatchId());
                    var side = e.getSide() == null ? null : e.getSide().name();
                    var fighter = e.getSide() == null
                            ? null
                            : d.competitors().name(e.getSide() == Side.RED ? m.getRedId() : m.getBlueId());
                    return Arrays.<Object>asList(
                            d.groups().get(m.getGroupId()).getNumber(),
                            m.getOrderIndex() + 1,
                            d.matNumbers().get(m.getMatId()),
                            positions.get(e.getId()),
                            SheetText.date(e.getAt(), zone),
                            SheetText.time(e.getAt(), zone),
                            SheetText.duration(e.getClockMs()),
                            SheetText.action(e.getType().name()),
                            SheetText.side(side),
                            fighter,
                            e.getReason(),
                            e.isAutomatic() ? "Automático" : actors.get(e.getActorAccountId()),
                            e.getTargetEventId() == null
                                    ? null
                                    : "Deshace la acción " + positions.get(e.getTargetEventId()),
                            undone.contains(e.getId()) ? "Sí" : "No");
                })
                .toList();
        return Csv.of(
                List.of(
                        "Grupo",
                        "Combate nº (en el grupo)",
                        "Tapiz",
                        "Acción nº",
                        "Fecha",
                        "Hora",
                        "Reloj del combate (m:ss)",
                        "Acción",
                        "Lado",
                        "Alumno o equipo",
                        "Motivo",
                        "Usuario",
                        "Deshacer",
                        "Deshecha después"),
                rows);
    }

    private Map<UUID, String> usernames(Set<UUID> ids) {
        return accounts.findAllById(ids).stream().collect(Collectors.toMap(Account::getId, Account::getEmail));
    }

    /** The disqualified side loses; otherwise the higher score. Only for finished matches. */
    static String winner(Match m, Competitor red, Competitor blue) {
        if (m.getStatus() != Match.Status.FINISHED) {
            return null;
        }
        if (m.getDisqualifiedSide() != null) {
            return Side.RED.name().equals(m.getDisqualifiedSide()) ? blue.name() : red.name();
        }
        if (m.getRedScore() == m.getBlueScore()) {
            return "Empate";
        }
        return m.getRedScore() > m.getBlueScore() ? red.name() : blue.name();
    }

    static String endReason(Match m, int pointsLimit, Competitor red, Competitor blue) {
        if (m.getStatus() != Match.Status.FINISHED) {
            return null;
        }
        if (m.getDisqualifiedSide() != null) {
            return "Descalificación de " + (Side.RED.name().equals(m.getDisqualifiedSide()) ? red.name() : blue.name());
        }
        if (Math.max(m.getRedScore(), m.getBlueScore()) >= pointsLimit) {
            return "Llegó a " + pointsLimit + " puntos";
        }
        return "Fin del tiempo";
    }
}
