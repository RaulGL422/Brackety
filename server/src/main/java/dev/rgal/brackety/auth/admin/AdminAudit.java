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
        ORGANIZER_VALIDATED
    }

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private Instant at;

    @Enumerated(EnumType.STRING)
    private Action action;

    private String target;

    protected AdminAudit() {}

    AdminAudit(Action action, String target, Instant at) {
        this.action = action;
        this.target = target;
        this.at = at;
    }
}
