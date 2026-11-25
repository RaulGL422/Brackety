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

    @Transactional
    public void supportChanged(UUID accountId, boolean enabled, String reason) {
        save(AdminAudit.Action.SUPPORT_CHANGED, accountId, (enabled ? "on: " : "off: ") + reason);
    }

    /** {@code what}: the change, as "group moved to mat 2". */
    @Transactional
    public void control(UUID target, String what) {
        save(AdminAudit.Action.CONTROL_CHANGE, target, what);
    }

    /** Debug environment only. {@code target}: the scenario's name or "clock". */
    @Transactional
    public void debug(String target, String what) {
        audit.save(new AdminAudit(AdminAudit.Action.DEBUG_CHANGE, target, what, clock.instant()));
    }

    private void save(AdminAudit.Action action, UUID target, String reason) {
        audit.save(new AdminAudit(action, target.toString(), reason, clock.instant()));
    }
}
