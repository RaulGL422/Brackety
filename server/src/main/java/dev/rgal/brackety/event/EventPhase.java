package dev.rgal.brackety.event;

import dev.rgal.brackety.event.Event.PhaseState;
import dev.rgal.brackety.event.EventPhaseChange.Action;
import dev.rgal.brackety.event.dto.PhaseView;
import java.time.Clock;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * A phase is started, played and finished (F1-7, Raul 2026-11-18). Groups are created and matches scored only while
 * it is in progress; finished, nobody changes the competition, the club included, until the club reopens it with a
 * reason. Every change stays in {@code event_phase_change}.
 */
@Service
public class EventPhase {

    static final String NOT_STARTED = "PHASE_NOT_STARTED";
    static final String FINISHED = "PHASE_FINISHED";

    private static final Logger log = LoggerFactory.getLogger(EventPhase.class);

    private final EventRepository events;
    private final EventPhaseChangeRepository changes;
    private final EventAccess access;
    private final ApplicationEventPublisher publisher;
    private final Clock clock;

    EventPhase(
            EventRepository events,
            EventPhaseChangeRepository changes,
            EventAccess access,
            ApplicationEventPublisher publisher,
            Clock clock) {
        this.events = events;
        this.changes = changes;
        this.access = access;
        this.publisher = publisher;
        this.clock = clock;
    }

    /** Creating groups, scoring and moving matches: only between start and finish. */
    public void requireInProgress(UUID eventId) {
        requireInProgress(state(eventId));
    }

    private static void requireInProgress(PhaseState state) {
        switch (state) {
            case NOT_STARTED ->
                throw EventException.conflict(NOT_STARTED, "The phase has not started: the club starts it.");
            case FINISHED -> throw finished();
            case IN_PROGRESS -> {}
        }
    }

    /** Teams, measures and mats can be prepared before the start, never once it is finished. */
    public void requireNotFinished(UUID eventId) {
        if (state(eventId) == PhaseState.FINISHED) {
            throw finished();
        }
    }

    public PhaseView view(UUID eventId, UUID accountId) {
        if (access.roles(eventId, accountId).isEmpty()) {
            throw EventException.notFound();
        }
        var event = events.findById(eventId).orElseThrow(EventException::notFound);
        return PhaseView.of(event, events.countPendingMatches(eventId));
    }

    @Transactional
    public PhaseView start(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventPermission.PHASE);
        var event = lock(eventId);
        if (event.phaseState() != PhaseState.NOT_STARTED) {
            throw EventException.conflict("PHASE_ALREADY_STARTED", "The phase has already started.");
        }
        event.start(clock.instant());
        changes.save(new EventPhaseChange(eventId, Action.START, accountId, null, 0, clock.instant()));
        log.info("Phase {} started", eventId);
        return PhaseView.of(event, events.countPendingMatches(eventId));
    }

    /** Pending matches stay unplayed (the app asks first); never with a match in progress or in review. */
    @Transactional
    public PhaseView finish(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventPermission.PHASE);
        var event = lock(eventId);
        requireInProgress(event.phaseState());
        if (events.hasMatchInProgressOrReview(eventId)) {
            throw EventException.conflict(
                    "MATCH_IN_PROGRESS", "A match is in progress or waits for the club's review: finish it first.");
        }
        close(event, Action.FINISH, accountId);
        return PhaseView.of(event, events.countPendingMatches(eventId));
    }

    @Transactional
    public PhaseView reopen(UUID eventId, UUID accountId, String reason) {
        access.require(eventId, accountId, EventRole.CLUB);
        var event = lock(eventId);
        if (event.phaseState() != PhaseState.FINISHED) {
            throw EventException.conflict("PHASE_NOT_FINISHED", "The phase is not finished.");
        }
        event.reopen();
        changes.save(new EventPhaseChange(eventId, Action.REOPEN, accountId, reason.strip(), 0, clock.instant()));
        log.info("Phase {} reopened", eventId);
        return PhaseView.of(event, events.countPendingMatches(eventId));
    }

    /** {@code accountId} null: it finished by itself (PhaseAutoClose). */
    void close(Event event, Action action, UUID accountId) {
        var unplayed = events.countPendingMatches(event.getId());
        event.finish(clock.instant());
        changes.save(new EventPhaseChange(event.getId(), action, accountId, null, unplayed, clock.instant()));
        log.info("Phase {} finished ({}), {} matches unplayed", event.getId(), action, unplayed);
        publisher.publishEvent(new PhaseFinished(event.getId()));
    }

    private Event lock(UUID eventId) {
        return events.lockById(eventId).orElseThrow(EventException::notFound);
    }

    private PhaseState state(UUID eventId) {
        return events.findById(eventId).orElseThrow(EventException::notFound).phaseState();
    }

    private static EventException finished() {
        return EventException.conflict(FINISHED, "The phase is finished: the club reopens it to change anything.");
    }
}
