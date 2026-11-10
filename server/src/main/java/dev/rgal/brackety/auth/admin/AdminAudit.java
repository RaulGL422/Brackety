package dev.rgal.brackety.auth.admin;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Instant;
import java.util.UUID;

@Entity
class AdminAudit {

    enum Action {
        ADMIN_LOGIN,
        LOCK_REVOKED,
        ORGANIZER_VALIDATED,
        MATCH_RESET,
        GROUP_DISSOLVED,
        COMPETITION_CLEARED
    }

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private Instant at;

    @Enumerated(EnumType.STRING)
    private Action action;

    private String target;

    /** Why: required for the event operations, null for the rest. */
    private String reason;

    protected AdminAudit() {}

    AdminAudit(Action action, String target, Instant at) {
        this(action, target, null, at);
    }

    AdminAudit(Action action, String target, String reason, Instant at) {
        this.action = action;
        this.target = target;
        this.reason = reason;
        this.at = at;
    }
}
