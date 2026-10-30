package dev.rgal.brackety.participant;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.participant.dto.ParticipantRequest;
import dev.rgal.brackety.participant.dto.ParticipantResponse;
import java.time.Clock;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ParticipantService {

    static final int ADULT_AGE = 18;

    private final ParticipantRepository participants;
    private final EventCategoryRepository categories;
    private final EventService events;
    private final EventAccess access;
    private final Clock clock;

    ParticipantService(
            ParticipantRepository participants,
            EventCategoryRepository categories,
            EventService events,
            EventAccess access,
            Clock clock) {
        this.participants = participants;
        this.categories = categories;
        this.events = events;
        this.access = access;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public List<ParticipantResponse> list(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB, EventRole.GROUPER);
        var event = events.get(eventId);
        var eventCategories = categories.findByEventIdOrderByMinAge(eventId);
        return participants.findByEventIdOrderByFirstNameAscLastNameAsc(eventId).stream()
                .map(p -> toResponse(p, event, eventCategories))
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
        // The birth date sets the category the participant's group was made for.
        if (!request.birthDate().equals(participant.getBirthDate()) && participants.isInAGroup(participantId)) {
            throw EventException.conflict("The birth date cannot change once the participant is in a group.");
        }
        return save(participant, request);
    }

    @Transactional
    public void delete(UUID eventId, UUID participantId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        var participant = find(eventId, participantId);
        if (participants.isInAGroup(participantId)) {
            throw EventException.conflict("A participant in a group cannot be removed.");
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
        participant.update(
                request.firstName().strip(),
                request.lastName().strip(),
                request.birthDate(),
                request.heightCm(),
                request.guardianConsent());
        participants.save(participant);
        return toResponse(participant, event, categories.findByEventIdOrderByMinAge(event.getId()));
    }

    static ParticipantResponse toResponse(Participant p, Event event, List<EventCategory> eventCategories) {
        var age = event.ageOf(p.getBirthDate());
        var category = eventCategories.stream().filter(c -> c.contains(age)).findFirst();
        return new ParticipantResponse(
                p.getId(),
                p.getFirstName(),
                p.getLastName(),
                p.getBirthDate(),
                p.getHeightCm(),
                p.hasGuardianConsent(),
                age,
                category.map(EventCategory::getId).orElse(null),
                category.map(EventCategory::getName).orElse(null));
    }
}
