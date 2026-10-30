package dev.rgal.brackety.auth.email;

import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.AuthEmails;
import java.time.Clock;
import java.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

// Accounts with an unverified email are deleted for good after 7 days; a reminder goes out on day 5.
@Component
class UnverifiedAccountPurge {

    static final Duration REMINDER_AFTER = Duration.ofDays(5);
    static final Duration DELETE_AFTER = Duration.ofDays(7);

    private static final Logger log = LoggerFactory.getLogger(UnverifiedAccountPurge.class);

    private final AccountRepository accounts;
    private final EmailTokens emailTokens;
    private final AuthEmails authEmails;
    private final Clock clock;

    UnverifiedAccountPurge(AccountRepository accounts, EmailTokens emailTokens, AuthEmails authEmails, Clock clock) {
        this.accounts = accounts;
        this.emailTokens = emailTokens;
        this.authEmails = authEmails;
        this.clock = clock;
    }

    // Also shortly after startup, so a local run with a shifted clock shows the effect right away.
    @Scheduled(initialDelayString = "${brackety.auth.unverified-purge-initial-delay}", fixedDelayString = "P1D")
    @Transactional
    public void run() {
        var now = clock.instant();
        var deleted = accounts.deleteUnverified(now.minus(DELETE_AFTER));
        var reminded = 0;
        for (var account : accounts.findUnverifiedNeedingReminder(now.minus(REMINDER_AFTER))) {
            if (account.isActive()) {
                authEmails.verificationReminder(
                        account, emailTokens.issue(account.getId(), EmailToken.Purpose.VERIFY_EMAIL));
                reminded++;
            }
            account.markReminderSent(now);
        }
        log.info("Unverified accounts: {} deleted, {} reminded", deleted, reminded);
    }
}
