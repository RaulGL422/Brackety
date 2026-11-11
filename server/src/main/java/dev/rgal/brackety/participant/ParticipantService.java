package dev.rgal.brackety.participant;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventOrganization;
import dev.rgal.brackety.event.EventOrganizationRepository;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.participant.dto.ParticipantRequest;
import dev.rgal.brackety.participant.dto.ParticipantResponse;
import java.time.Clock;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ParticipantService {

    public static final int ADULT_AGE = 18;

    private final ParticipantRepository participants;
    private final EventCategoryRepository categories;
    private final EventOrganizationRepository organizations;
    private final EventService events;
    private final EventAccess access;
    private final Clock clock;

    ParticipantService(
            ParticipantRepository participants,
            EventCategoryRepository categories,
            EventOrganizationRepository organizations,
            EventService events,
            EventAccess access,
            Clock clock) {
        this.participants = participants;
        this.categories = categories;
        this.organizations = organizations;
        this.events = events;
        this.access = access;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public List<ParticipantResponse> list(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        var event = events.get(eventId);
        var eventCategories = categories.findByEventIdOrderByMinAge(eventId);
        var organizationNames = organizationNames(organizations, eventId);
        return participants.findByEventIdOrderByFirstNameAscLastNameAsc(eventId).stream()
                .map(p -> toResponse(p, event, eventCategories, organizationNames))
                .toList();
    }

    @Transactional
    public ParticipantResponse create(UUID eventId, UUID accountId, ParticipantRequest request) {
        access.require(eventId, accountId, EventRole.CLUB);
        var participant = new Participant(eventId, clock.instant());
        return save(participant, request);
    }

    @Transactional
    public ParticipantResponse update(UUID eventId, UUID participantId, UUID accountId, ParticipantRequest request) {
        access.require(eventId, accountId, EventRole.CLUB);
        var participant = find(eventId, participantId);
        // The birth date and the chosen category set the category their group or team was made for.
        var changesCategory = !request.birthDate().equals(participant.getBirthDate())
                || !Objects.equals(request.categoryId(), participant.getCategoryId());
        if (changesCategory && participants.isInAGroupOrTeam(participantId)) {
            throw EventException.conflict(
                    "The birth date and category cannot change once the participant is in a group or team.");
        }
        return save(participant, request);
    }

    @Transactional
    public void delete(UUID eventId, UUID participantId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        var participant = find(eventId, participantId);
        if (participants.isInAGroupOrTeam(participantId)) {
            throw EventException.conflict("A participant in a group or team cannot be removed.");
        }
        participants.delete(participant);
    }

    private Participant find(UUID eventId, UUID participantId) {
        return participants
                .findById(participantId)
                .filter(p -> p.getEventId().equals(eventId))
                .orElseThrow(EventException::notFound);
    }

    private ParticipantResponse save(Participant participant, ParticipantRequest request) {
        var event = events.get(participant.getEventId());
        if (event.ageOf(request.birthDate()) < ADULT_AGE && !request.guardianConsent()) {
            throw EventException.invalid("A minor needs the guardian's consent.");
        }
        var eventCategories = categories.findByEventIdOrderByMinAge(event.getId());
        if (request.categoryId() != null
                && eventCategories.stream().noneMatch(c -> c.getId().equals(request.categoryId()))) {
            throw EventException.invalid("The category is not from this event.");
        }
        var organizationNames = organizationNames(organizations, event.getId());
        if (request.organizationId() != null && !organizationNames.containsKey(request.organizationId())) {
            throw EventException.invalid("The organization is not from this event.");
        }
        participant.update(
                request.firstName().strip(),
                request.lastName().strip(),
                request.birthDate(),
                request.heightCm(),
                request.guardianConsent(),
                request.categoryId());
        participant.setOrganizationId(request.organizationId());
        participants.save(participant);
        return toResponse(participant, event, eventCategories, organizationNames);
    }

    public static Map<UUID, String> organizationNames(EventOrganizationRepository organizations, UUID eventId) {
        return organizations.findByEventIdOrderByName(eventId).stream()
                .collect(Collectors.toMap(EventOrganization::getId, EventOrganization::getName));
    }

    static ParticipantResponse toResponse(
            Participant p, Event event, List<EventCategory> eventCategories, Map<UUID, String> organizationNames) {
        var age = event.ageOf(p.getBirthDate());
        var category = p.categoryIn(event, eventCategories);
        return new ParticipantResponse(
                p.getId(),
                p.getFirstName(),
                p.getLastName(),
                p.getBirthDate(),
                p.getHeightCm(),
                p.hasGuardianConsent(),
                age,
                category.map(EventCategory::getId).orElse(null),
                category.map(EventCategory::getName).orElse(null),
                p.getCategoryId(),
                p.getOrganizationId(),
                organizationNames.get(p.getOrganizationId()),
                p.getPersonId());
    }
}
