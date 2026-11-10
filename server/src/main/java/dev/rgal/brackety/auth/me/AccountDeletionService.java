package dev.rgal.brackety.auth.me;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.AuthEmails;
import dev.rgal.brackety.auth.dto.DeletionResponse;
import dev.rgal.brackety.auth.session.SessionService;
import dev.rgal.brackety.event.EventRepository;
import java.time.Clock;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Logical deletion: the owner can restore the account by signing in until DeletedAccountPurge removes it.
@Service
public class AccountDeletionService {

    private final AccountRepository accounts;
    private final EventRepository events;
    private final SessionService sessions;
    private final AuthEmails authEmails;
    private final Clock clock;

    AccountDeletionService(
            AccountRepository accounts,
            EventRepository events,
            SessionService sessions,
            AuthEmails authEmails,
            Clock clock) {
        this.accounts = accounts;
        this.events = events;
        this.sessions = sessions;
        this.authEmails = authEmails;
        this.clock = clock;
    }

    // An owned event holds other people's data: it is handed over or deleted first, never left without owner.
    @Transactional
    DeletionResponse delete(UUID accountId) {
        var account = accounts.lockById(accountId).filter(Account::isActive).orElseThrow(AuthException::invalidSession);
        return schedule(account);
    }

    /** For the owner or the superadmin: {@code account} is active and locked by the caller. */
    @Transactional
    public DeletionResponse schedule(Account account) {
        if (events.existsByOwnerAccountId(account.getId())) {
            throw AuthException.ownsEvents();
        }
        account.markDeleted(clock.instant());
        sessions.closeAll(account);
        var deletesOn = account.deletesOn(clock.getZone());
        authEmails.deletionScheduled(account, deletesOn);
        return new DeletionResponse(deletesOn);
    }
}
