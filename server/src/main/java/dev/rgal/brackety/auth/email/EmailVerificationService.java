package dev.rgal.brackety.auth.email;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.AuthEmails;
import java.time.Clock;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class EmailVerificationService {

    private final AccountRepository accounts;
    private final EmailTokens emailTokens;
    private final AuthEmails authEmails;
    private final Clock clock;

    EmailVerificationService(AccountRepository accounts, EmailTokens emailTokens, AuthEmails authEmails, Clock clock) {
        this.accounts = accounts;
        this.emailTokens = emailTokens;
        this.authEmails = authEmails;
        this.clock = clock;
    }

    @Transactional
    public void verify(String token) {
        var accountId = emailTokens.consume(token, EmailToken.Purpose.VERIFY_EMAIL);
        var account = accounts.findById(accountId).filter(Account::isActive).orElseThrow(AuthException::invalidLink);
        account.markEmailVerified(clock.instant());
    }

    // Says nothing back: whether the account exists, is verified or hit the limit stays hidden.
    @Transactional
    public void resend(String email) {
        accounts.lockByEmail(AuthService.normalize(email))
                .filter(a -> a.isActive() && !a.isEmailVerified())
                .ifPresent(account -> emailTokens
                        .issueThrottled(account.getId(), EmailToken.Purpose.VERIFY_EMAIL)
                        .ifPresent(token -> authEmails.verifyEmail(account, token)));
    }
}
