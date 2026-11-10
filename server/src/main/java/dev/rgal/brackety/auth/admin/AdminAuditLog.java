package dev.rgal.brackety.auth.admin;

import java.time.Clock;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** What the superadmin did to an event, with the reason given; for the features outside {@code auth}. */
@Service
public class AdminAuditLog {

    private final AdminAuditRepository audit;
    private final Clock clock;

    AdminAuditLog(AdminAuditRepository audit, Clock clock) {
        this.audit = audit;
        this.clock = clock;
    }

    @Transactional
    public void matchReset(UUID matchId, String reason) {
        save(AdminAudit.Action.MATCH_RESET, matchId, reason);
    }

    @Transactional
    public void groupDissolved(UUID groupId, String reason) {
        save(AdminAudit.Action.GROUP_DISSOLVED, groupId, reason);
    }

    @Transactional
    public void competitionCleared(UUID eventId, String reason) {
        save(AdminAudit.Action.COMPETITION_CLEARED, eventId, reason);
    }

    @Transactional
    public void userSuspended(UUID accountId, String reason) {
        save(AdminAudit.Action.USER_SUSPENDED, accountId, reason);
    }

    @Transactional
    public void userUnsuspended(UUID accountId, String reason) {
        save(AdminAudit.Action.USER_UNSUSPENDED, accountId, reason);
    }

    @Transactional
    public void userDeleted(UUID accountId, String reason) {
        save(AdminAudit.Action.USER_DELETED, accountId, reason);
    }

    private void save(AdminAudit.Action action, UUID target, String reason) {
        audit.save(new AdminAudit(action, target.toString(), reason, clock.instant()));
    }
}
