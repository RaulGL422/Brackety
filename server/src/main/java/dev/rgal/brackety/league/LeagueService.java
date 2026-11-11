package dev.rgal.brackety.league;

import dev.rgal.brackety.event.Discipline;
import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventOrganization;
import dev.rgal.brackety.event.EventOrganizationRepository;
import dev.rgal.brackety.event.EventRepository;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.event.EventStaff;
import dev.rgal.brackety.event.EventStaffRepository;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.league.dto.LeagueDtos.Candidate;
import dev.rgal.brackety.league.dto.LeagueDtos.CategoryPodiumDto;
import dev.rgal.brackety.league.dto.LeagueDtos.DisciplineResponse;
import dev.rgal.brackety.league.dto.LeagueDtos.LeagueRequest;
import dev.rgal.brackety.league.dto.LeagueDtos.LeagueResponse;
import dev.rgal.brackety.league.dto.LeagueDtos.NewPhaseRequest;
import dev.rgal.brackety.league.dto.LeagueDtos.PhaseResponse;
import dev.rgal.brackety.league.dto.LeagueDtos.ReenrolRequest;
import dev.rgal.brackety.league.dto.LeagueDtos.ReenrolResponse;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import dev.rgal.brackety.participant.ParticipantService;
import java.time.Clock;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * A league by phases: each phase is an event with its own entries; the same person keeps one person id across
 * phases, so their points add up (docs/modulos/liga-fases.md). Only the club of a phase manages its league.
 */
@Service
public class LeagueService {

    private final LeagueRepository leagues;
    private final CategoryPodiumRepository podiums;
    private final EventRepository events;
    private final EventService eventService;
    private final EventStaffRepository staff;
    private final MatRepository mats;
    private final EventCategoryRepository categories;
    private final EventOrganizationRepository organizations;
    private final ParticipantRepository participants;
    private final EventAccess access;
    private final Clock clock;

    LeagueService(
            LeagueRepository leagues,
            CategoryPodiumRepository podiums,
            EventRepository events,
            EventService eventService,
            EventStaffRepository staff,
            MatRepository mats,
            EventCategoryRepository categories,
            EventOrganizationRepository organizations,
            ParticipantRepository participants,
            EventAccess access,
            Clock clock) {
        this.leagues = leagues;
        this.podiums = podiums;
        this.events = events;
        this.eventService = eventService;
        this.staff = staff;
        this.mats = mats;
        this.categories = categories;
        this.organizations = organizations;
        this.participants = participants;
        this.access = access;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public LeagueResponse league(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        return response(leagueOf(eventId));
    }

    @Transactional
    public LeagueResponse update(UUID eventId, UUID accountId, LeagueRequest request) {
        access.require(eventId, accountId, EventRole.CLUB);
        var league = leagueOf(eventId);
        var names = new HashSet<String>();
        for (var c : request.categoryPodiums()) {
            if (!names.add(c.categoryName().strip())) {
                throw EventException.invalid("A category has two podiums.");
            }
        }
        league.update(request.name().strip(), request.podium());
        podiums.deleteByLeague(league.getId());
        for (var c : request.categoryPodiums()) {
            podiums.save(new CategoryPodium(league.getId(), c.categoryName().strip(), c.podium()));
        }
        return response(league);
    }

    /** Creates the next phase from this one's configuration; it has no entries yet. Returns its event id. */
    @Transactional
    public PhaseResponse createPhase(UUID eventId, UUID accountId, NewPhaseRequest request) {
        access.require(eventId, accountId, EventRole.CLUB);
        if (!request.discipline().isAvailable()) {
            throw EventException.invalid("That discipline has no scoreboard yet.");
        }
        var source = eventService.get(eventId);
        var phases = events.findByLeagueIdOrderByPhaseNumber(source.getLeagueId());
        var number = phases.getLast().getPhaseNumber() + 1;
        var phase = events.save(source.nextPhase(
                number,
                request.discipline(),
                request.name().strip(),
                request.date(),
                request.attendancePoints(),
                clock.instant()));
        for (var member : staff.findByEventId(eventId)) {
            staff.save(new EventStaff(phase.getId(), member.getAccountId(), member.getRole()));
        }
        for (var mat : mats.findByEventIdOrderByNumber(eventId)) {
            mats.save(new Mat(phase.getId(), mat.getNumber(), mat.getRefereeAccountId()));
        }
        for (var c : categories.findByEventIdOrderByMinAge(eventId)) {
            categories.save(
                    new EventCategory(phase.getId(), c.getName(), c.getMinAge(), c.getMaxAge(), c.getTeamSize()));
        }
        for (var o : organizations.findByEventIdOrderByName(eventId)) {
            organizations.save(new EventOrganization(phase.getId(), o.getName(), o.getShortName()));
        }
        return new PhaseResponse(
                phase.getId(), number, phase.getName(), phase.getEventDate(), phase.getDiscipline(), 0);
    }

    /** People of the other phases not entered in this one, with their latest entry, by name. */
    @Transactional(readOnly = true)
    public List<Candidate> candidates(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        var event = eventService.get(eventId);
        var latest = latestEntries(event);
        var phaseNumbers = phaseNumbers(event.getLeagueId());
        var organizationNames = new HashMap<UUID, String>();
        var eventsById = events.findAllById(phaseNumbers.keySet()).stream()
                .collect(Collectors.toMap(Event::getId, Function.identity()));
        var categoriesByEvent = new HashMap<UUID, List<EventCategory>>();
        return latest.values().stream()
                .map(p -> {
                    var phase = eventsById.get(p.getEventId());
                    var phaseCategories =
                            categoriesByEvent.computeIfAbsent(p.getEventId(), categories::findByEventIdOrderByMinAge);
                    var organizationName = p.getOrganizationId() == null
                            ? null
                            : organizationNames.computeIfAbsent(
                                    p.getOrganizationId(),
                                    id -> organizations
                                            .findById(id)
                                            .map(EventOrganization::getName)
                                            .orElse(null));
                    return new Candidate(
                            p.getPersonId(),
                            p.getFirstName(),
                            p.getLastName(),
                            p.getBirthDate(),
                            event.ageOf(p.getBirthDate()),
                            organizationName,
                            p.categoryIn(phase, phaseCategories)
                                    .map(EventCategory::getName)
                                    .orElse(null),
                            phase.getPhaseNumber());
                })
                .sorted(Comparator.comparing(Candidate::firstName, String.CASE_INSENSITIVE_ORDER)
                        .thenComparing(Candidate::lastName, String.CASE_INSENSITIVE_ORDER))
                .toList();
    }

    /**
     * Enters people of other phases in this one with their latest data. The category follows their age here (one
     * chosen by hand is not carried over); the organization is the one with the same name in this phase, if any.
     */
    @Transactional
    public ReenrolResponse reenrol(UUID eventId, UUID accountId, ReenrolRequest request) {
        access.require(eventId, accountId, EventRole.CLUB);
        var event = eventService.get(eventId);
        var latest = latestEntries(event);
        var organizationIds = organizations.findByEventIdOrderByName(eventId).stream()
                .collect(Collectors.toMap(EventOrganization::getName, EventOrganization::getId));
        var organizationNames = new HashMap<UUID, String>();
        var added = 0;
        for (var personId : new HashSet<>(request.personIds())) {
            var previous = latest.get(personId);
            if (previous == null) {
                throw EventException.invalid("Someone is not in another phase of the league, or already entered.");
            }
            var minor = event.ageOf(previous.getBirthDate()) < ParticipantService.ADULT_AGE;
            if (minor && !request.guardianConsent()) {
                throw EventException.invalid("A minor needs the guardian's consent.");
            }
            var participant = new Participant(eventId, personId, clock.instant());
            participant.update(
                    previous.getFirstName(),
                    previous.getLastName(),
                    previous.getBirthDate(),
                    previous.getHeightCm(),
                    minor ? request.guardianConsent() : previous.hasGuardianConsent());
            if (previous.getOrganizationId() != null) {
                var name = organizationNames.computeIfAbsent(
                        previous.getOrganizationId(),
                        id -> organizations
                                .findById(id)
                                .map(EventOrganization::getName)
                                .orElse(""));
                participant.setOrganizationId(organizationIds.get(name));
            }
            participants.save(participant);
            added++;
        }
        return new ReenrolResponse(added);
    }

    /** Person id → their entry in the latest other phase, for those not entered in {@code event}. */
    private Map<UUID, Participant> latestEntries(Event event) {
        var phaseNumbers = phaseNumbers(event.getLeagueId());
        var here = participants.findByEventIdOrderByFirstNameAscLastNameAsc(event.getId()).stream()
                .map(Participant::getPersonId)
                .collect(Collectors.toSet());
        var others = phaseNumbers.keySet().stream()
                .filter(id -> !id.equals(event.getId()))
                .toList();
        var latest = new LinkedHashMap<UUID, Participant>();
        participants.findByEventIdIn(others).stream()
                .filter(p -> !here.contains(p.getPersonId()))
                .sorted(Comparator.comparingInt(p -> phaseNumbers.get(p.getEventId())))
                .forEach(p -> latest.put(p.getPersonId(), p));
        return latest;
    }

    private Map<UUID, Integer> phaseNumbers(UUID leagueId) {
        return events.findByLeagueIdOrderByPhaseNumber(leagueId).stream()
                .collect(Collectors.toMap(Event::getId, Event::getPhaseNumber));
    }

    private League leagueOf(UUID eventId) {
        var event = eventService.get(eventId);
        return leagues.findById(event.getLeagueId()).orElseThrow(EventException::notFound);
    }

    private LeagueResponse response(League league) {
        var phases = events.findByLeagueIdOrderByPhaseNumber(league.getId());
        var counts = participants
                .findByEventIdIn(phases.stream().map(Event::getId).toList())
                .stream()
                .collect(Collectors.groupingBy(Participant::getEventId, Collectors.counting()));
        var categoryNames = phases.stream()
                .flatMap(e -> categories.findByEventIdOrderByMinAge(e.getId()).stream())
                .sorted(Comparator.comparingInt(EventCategory::getMinAge))
                .map(EventCategory::getName)
                .distinct()
                .toList();
        return new LeagueResponse(
                league.getId(),
                league.getName(),
                league.getPodium(),
                podiums.findByLeagueIdOrderByCategoryName(league.getId()).stream()
                        .map(c -> new CategoryPodiumDto(c.getCategoryName(), c.getPodium()))
                        .toList(),
                phases.stream()
                        .map(e -> new PhaseResponse(
                                e.getId(),
                                e.getPhaseNumber(),
                                e.getName(),
                                e.getEventDate(),
                                e.getDiscipline(),
                                counts.getOrDefault(e.getId(), 0L).intValue()))
                        .toList(),
                categoryNames,
                Arrays.stream(Discipline.values())
                        .map(d -> new DisciplineResponse(d, d.isAvailable()))
                        .toList());
    }
}
