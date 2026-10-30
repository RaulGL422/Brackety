package dev.rgal.brackety.auth.email;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.AuthEmails;
import dev.rgal.brackety.auth.session.RefreshTokenRepository;
import java.time.Clock;
import java.util.UUID;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// The new address is proved by its link before it replaces the old one; Google identities do not change.
@Service
public class EmailChangeService {

    private final AccountRepository accounts;
    private final RefreshTokenRepository refreshTokens;
    private final EmailTokens emailTokens;
    private final AuthEmails authEmails;
    private final Clock clock;

    EmailChangeService(
            AccountRepository accounts,
            RefreshTokenRepository refreshTokens,
            EmailTokens emailTokens,
            AuthEmails authEmails,
            Clock clock) {
        this.accounts = accounts;
        this.refreshTokens = refreshTokens;
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
        emailTokens
                .issueThrottled(accountId, EmailToken.Purpose.CHANGE_EMAIL, email)
                .ifPresent(token -> accounts.findByEmail(email)
                        .ifPresentOrElse(
                                authEmails::emailInUse, () -> authEmails.confirmEmailChange(account, email, token)));
    }

    // Every session is closed, as on a password reset: whoever asked for the change may not be the owner.
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
        var now = clock.instant();
        account.changeEmail(change.newEmail(), now);
        try {
            accounts.flush();
        } catch (DataIntegrityViolationException e) {
            // A sign-up with that address committed between the check and this update.
            throw AuthException.invalidLink();
        }
        refreshTokens.revokeAccount(account.getId(), now);
        authEmails.emailChanged(oldEmail, account);
    }
}
