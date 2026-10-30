package dev.rgal.brackety.auth.me;

import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import java.time.Clock;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionOperations;

// Accounts deleted 30 days ago go for good, with everything they own (on delete cascade).
// One transaction per account: one that cannot go must not keep the others.
@Component
class DeletedAccountPurge {

    private static final Logger log = LoggerFactory.getLogger(DeletedAccountPurge.class);

    private final AccountRepository accounts;
    private final TransactionOperations transactions;
    private final Clock clock;

    DeletedAccountPurge(AccountRepository accounts, TransactionOperations transactions, Clock clock) {
        this.accounts = accounts;
        this.transactions = transactions;
        this.clock = clock;
    }

    // Also shortly after startup, so a local run with a shifted clock shows the effect right away.
    // eventos/ranking: anonymise the results of each account here before it goes (doc 06), once results exist.
    // Event staff roles go with the account and mats lose their referee. An event owner cannot be deleted
    // (DELETE /me answers 409), so an owner that got here anyway fails on the foreign key and is logged.
    @Scheduled(initialDelayString = "${brackety.auth.deleted-purge-initial-delay}", fixedDelayString = "P1D")
    public void run() {
        var deletedBefore = clock.instant().minus(Account.DELETION_GRACE);
        int purged = 0;
        for (var id : accounts.findIdsDeletedBefore(deletedBefore)) {
            try {
                purged += transactions.execute(status -> accounts.deleteIfDeletedBefore(id, deletedBefore));
            } catch (DataAccessException e) {
                log.error(
                        "Deleted account {} could not be purged: {}",
                        id,
                        e.getMostSpecificCause().getMessage());
            }
        }
        log.info("Deleted accounts purged for good: {}", purged);
    }
}
