package dev.rgal.brackety.auth.me;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.AuthEmails;
import dev.rgal.brackety.auth.dto.DeletionResponse;
import dev.rgal.brackety.auth.session.SessionService;
import java.time.Clock;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Logical deletion: the owner can restore the account by signing in until DeletedAccountPurge removes it.
@Service
public class AccountDeletionService {

    private final AccountRepository accounts;
    private final List<AccountDeletionBlocker> blockers;
    private final SessionService sessions;
    private final AuthEmails authEmails;
    private final Clock clock;

    AccountDeletionService(
            AccountRepository accounts,
            List<AccountDeletionBlocker> blockers,
            SessionService sessions,
            AuthEmails authEmails,
            Clock clock) {
        this.accounts = accounts;
        this.blockers = blockers;
        this.sessions = sessions;
        this.authEmails = authEmails;
        this.clock = clock;
    }

    // What the account owns for others (its events) is handed over or deleted first.
    @Transactional
    DeletionResponse delete(UUID accountId) {
        var account = accounts.lockById(accountId).filter(Account::isActive).orElseThrow(AuthException::invalidSession);
        return schedule(account);
    }

    /** For the owner or the superadmin: {@code account} is active and locked by the caller. */
    @Transactional
    public DeletionResponse schedule(Account account) {
        if (blockers.stream().anyMatch(blocker -> blocker.blocksDeletion(account.getId()))) {
            throw AuthException.ownsEvents();
        }
        account.markDeleted(clock.instant());
        sessions.closeAll(account);
        var deletesOn = account.deletesOn(clock.getZone());
        authEmails.deletionScheduled(account, deletesOn);
        return new DeletionResponse(deletesOn);
    }
}
