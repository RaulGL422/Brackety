package dev.rgal.brackety.auth.admin;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.lockout.LoginAttempt;
import dev.rgal.brackety.auth.lockout.LoginAttemptRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class AdminLockService {

    private final LoginAttemptRepository loginAttempts;
    private final AccountRepository accounts;
    private final AdminAuditRepository audit;
    private final Clock clock;

    AdminLockService(
            LoginAttemptRepository loginAttempts, AccountRepository accounts, AdminAuditRepository audit, Clock clock) {
        this.loginAttempts = loginAttempts;
        this.accounts = accounts;
        this.audit = audit;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public List<LockResponse> activeLocks() {
        var locks = loginAttempts.findLocked(clock.instant());
        var accountIds = locks.stream()
                .map(LoginAttempt::getAccountId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        Map<UUID, String> emails =
                accounts.findAllById(accountIds).stream().collect(Collectors.toMap(Account::getId, Account::getEmail));
        return locks.stream()
                .map(lock -> new LockResponse(
                        lock.getLockId(),
                        lock.isEmailKey() ? LockResponse.Type.EMAIL : LockResponse.Type.IP,
                        lock.getLockedUntil(),
                        lock.getAccountId() == null ? null : emails.get(lock.getAccountId()),
                        lock.getIp()))
                .toList();
    }

    /** Lifts the lock and clears its failures, so the user can try again at once. */
    @Transactional
    public void revoke(String lockId) {
        var now = clock.instant();
        var lock =
                loginAttempts.lockByLockId(lockId).filter(a -> a.isLocked(now)).orElseThrow(AuthException::notFound);
        lock.reset();
        audit.save(new AdminAudit(AdminAudit.Action.LOCK_REVOKED, lockId, now));
    }

    /** {@code email} is the account one, if the email has an account; {@code ip} only for an IP lock. */
    record LockResponse(String lockId, Type type, Instant lockedUntil, String email, String ip) {

        enum Type {
            EMAIL,
            IP
        }
    }
}
