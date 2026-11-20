package dev.rgal.brackety.event;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Instant;
import java.util.UUID;

/** Who started, finished or reopened a phase, when, and why: the phase's history (F1-7). */
@Entity
class EventPhaseChange {

    enum Action {
        START,
        FINISH,
        AUTO_FINISH,
        REOPEN
    }

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID eventId;

    @Enumerated(EnumType.STRING)
    private Action action;

    private UUID accountId;
    private String reason;
    private int unplayedMatches;
    private Instant createdAt;

    protected EventPhaseChange() {}

    EventPhaseChange(UUID eventId, Action action, UUID accountId, String reason, int unplayedMatches, Instant now) {
        this.eventId = eventId;
        this.action = action;
        this.accountId = accountId;
        this.reason = reason;
        this.unplayedMatches = unplayedMatches;
        this.createdAt = now;
    }
}
