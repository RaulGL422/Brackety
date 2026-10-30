package dev.rgal.brackety.auth.me;

import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import java.time.Clock;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

// Accounts deleted 30 days ago go for good, with everything they own (on delete cascade).
@Component
class DeletedAccountPurge {

    private static final Logger log = LoggerFactory.getLogger(DeletedAccountPurge.class);

    private final AccountRepository accounts;
    private final Clock clock;

    DeletedAccountPurge(AccountRepository accounts, Clock clock) {
        this.accounts = accounts;
        this.clock = clock;
    }

    // Also shortly after startup, so a local run with a shifted clock shows the effect right away.
    @Scheduled(initialDelayString = "${brackety.auth.deleted-purge-initial-delay}", fixedDelayString = "P1D")
    @Transactional
    public void run() {
        // eventos/ranking: before this delete, anonymise the results of these accounts (doc 06) so they
        // stay in rankings and events without the person. Nothing to anonymise until those modules exist.
        var purged = accounts.deleteDeletedBefore(clock.instant().minus(Account.DELETION_GRACE));
        log.info("Deleted accounts purged for good: {}", purged);
    }
}
