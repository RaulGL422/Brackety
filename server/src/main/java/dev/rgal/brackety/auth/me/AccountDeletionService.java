package dev.rgal.brackety.auth.me;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.AuthEmails;
import dev.rgal.brackety.auth.dto.DeletionResponse;
import dev.rgal.brackety.auth.session.RefreshTokenRepository;
import java.time.Clock;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Logical deletion: the owner can restore the account by signing in until DeletedAccountPurge removes it.
@Service
class AccountDeletionService {

    private final AccountRepository accounts;
    private final RefreshTokenRepository refreshTokens;
    private final AuthEmails authEmails;
    private final Clock clock;

    AccountDeletionService(
            AccountRepository accounts, RefreshTokenRepository refreshTokens, AuthEmails authEmails, Clock clock) {
        this.accounts = accounts;
        this.refreshTokens = refreshTokens;
        this.authEmails = authEmails;
        this.clock = clock;
    }

    @Transactional
    DeletionResponse delete(UUID accountId) {
        var account = accounts.lockById(accountId).filter(Account::isActive).orElseThrow(AuthException::invalidSession);
        var now = clock.instant();
        account.markDeleted(now);
        refreshTokens.revokeAccount(accountId, now);
        var deletesOn = account.deletesOn(clock.getZone());
        authEmails.deletionScheduled(account, deletesOn);
        return new DeletionResponse(deletesOn);
    }
}
