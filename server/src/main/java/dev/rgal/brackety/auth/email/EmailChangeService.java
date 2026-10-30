package dev.rgal.brackety.auth.email;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.AuthEmails;
import dev.rgal.brackety.auth.session.SessionService;
import java.time.Clock;
import java.util.UUID;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// The new address is proved by its link before it replaces the old one; Google identities do not change.
@Service
public class EmailChangeService {

    private final AccountRepository accounts;
    private final SessionService sessions;
    private final EmailTokens emailTokens;
    private final AuthEmails authEmails;
    private final Clock clock;

    EmailChangeService(
            AccountRepository accounts,
            SessionService sessions,
            EmailTokens emailTokens,
            AuthEmails authEmails,
            Clock clock) {
        this.accounts = accounts;
        this.sessions = sessions;
        this.emailTokens = emailTokens;
        this.authEmails = authEmails;
        this.clock = clock;
    }

    // Says nothing back: whether the address is taken or the limit was hit stays hidden. The token is
    // stored even when the address is taken, so both paths do the same work; it fails on confirmation.
    @Transactional
    public void request(UUID accountId, String newEmail) {
        var account = accounts.lockById(accountId).filter(Account::isActive).orElseThrow(AuthException::invalidSession);
        var email = Account.normalizeEmail(newEmail);
        if (email.equals(account.getEmail())) {
            return;
        }
        emailTokens
                .issueThrottled(accountId, EmailToken.Purpose.CHANGE_EMAIL, email)
                .ifPresent(token -> accounts.findByEmail(email)
                        .ifPresentOrElse(
                                authEmails::emailInUse, () -> authEmails.confirmEmailChange(account, email, token)));
    }

    // Every session and pending link is closed, as on a password reset: whoever asked for the change may not
    // be the owner, and links sent to the old address must not work any more.
    @Transactional
    public void confirm(String token) {
        var change = emailTokens.consumeEmailChange(token);
        var account =
                accounts.lockById(change.accountId()).filter(Account::isActive).orElseThrow(AuthException::invalidLink);
        // Someone may have taken the address since the link was sent.
        if (accounts.lockByEmail(change.newEmail()).isPresent()) {
            throw AuthException.invalidLink();
        }
        var oldEmail = account.getEmail();
        account.changeEmail(change.newEmail(), clock.instant());
        try {
            accounts.flush();
        } catch (DataIntegrityViolationException e) {
            // A sign-up with that address committed between the check and this update.
            throw AuthException.invalidLink();
        }
        sessions.closeAll(account);
        authEmails.emailChanged(oldEmail, account);
    }
}
