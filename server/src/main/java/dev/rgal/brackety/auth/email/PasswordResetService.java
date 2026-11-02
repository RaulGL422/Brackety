package dev.rgal.brackety.auth.email;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.AuthEmails;
import dev.rgal.brackety.auth.lockout.LoginAttempt;
import dev.rgal.brackety.auth.lockout.LoginAttemptRepository;
import dev.rgal.brackety.auth.session.SessionService;
import java.time.Clock;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PasswordResetService {

    private final AccountRepository accounts;
    private final SessionService sessions;
    private final LoginAttemptRepository loginAttempts;
    private final EmailTokens emailTokens;
    private final AuthEmails authEmails;
    private final PasswordEncoder passwordEncoder;
    private final Clock clock;

    PasswordResetService(
            AccountRepository accounts,
            SessionService sessions,
            LoginAttemptRepository loginAttempts,
            EmailTokens emailTokens,
            AuthEmails authEmails,
            PasswordEncoder passwordEncoder,
            Clock clock) {
        this.accounts = accounts;
        this.sessions = sessions;
        this.loginAttempts = loginAttempts;
        this.emailTokens = emailTokens;
        this.authEmails = authEmails;
        this.passwordEncoder = passwordEncoder;
        this.clock = clock;
    }

    // Says nothing back: whether the account exists or hit the limit stays hidden.
    @Transactional
    public void forgot(String email) {
        accounts.lockByEmail(Account.normalizeEmail(email))
                .filter(Account::isActive)
                .ifPresent(account -> emailTokens
                        .issueThrottled(account.getId(), EmailToken.Purpose.RESET_PASSWORD)
                        .ifPresent(token -> authEmails.resetPassword(account, token)));
    }

    // Lets the reset page say the link is dead before the user types a new password. The token is untouched.
    // Not read-only: the shared lookup locks the token row, which a read-only transaction refuses.
    @Transactional
    public void check(String token) {
        activeAccount(emailTokens.check(token, EmailToken.Purpose.RESET_PASSWORD));
    }

    // Opening the link proves the inbox is theirs, so it also verifies the email.
    // Every session and pending link is closed: whoever knew the old password may be logged in, or may
    // have asked for an email change.
    // The email lock goes too, so someone locking the account on purpose cannot keep the owner out.
    // The IP counter stays: it protects other accounts.
    @Transactional
    public void reset(String token, String newPassword) {
        var account = activeAccount(emailTokens.consume(token, EmailToken.Purpose.RESET_PASSWORD));
        var now = clock.instant();
        account.changePassword(passwordEncoder.encode(newPassword), now);
        account.markEmailVerified(now);
        sessions.closeAll(account);
        loginAttempts.deleteById(LoginAttempt.emailKey(account.getEmail()));
        authEmails.passwordChanged(account);
    }

    private Account activeAccount(UUID accountId) {
        return accounts.findById(accountId).filter(Account::isActive).orElseThrow(AuthException::invalidLink);
    }
}
