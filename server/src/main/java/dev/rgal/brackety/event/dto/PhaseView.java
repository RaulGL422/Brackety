package dev.rgal.brackety.event.dto;

import dev.rgal.brackety.event.Event;
import java.time.Instant;

/** The phase as the staff sees it (F1-7); {@code pendingMatches}: what finishing now leaves unplayed. */
public record PhaseView(Event.PhaseState state, Instant startedAt, Instant finishedAt, int pendingMatches) {

    public static PhaseView of(Event event, int pendingMatches) {
        return new PhaseView(event.phaseState(), event.getStartedAt(), event.getFinishedAt(), pendingMatches);
    }
}
