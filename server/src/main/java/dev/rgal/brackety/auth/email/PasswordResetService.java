package dev.rgal.brackety.auth.email;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.AuthEmails;
import dev.rgal.brackety.auth.lockout.LoginAttempt;
import dev.rgal.brackety.auth.lockout.LoginAttemptRepository;
import dev.rgal.brackety.auth.session.RefreshTokenRepository;
import java.time.Clock;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PasswordResetService {

    private final AccountRepository accounts;
    private final RefreshTokenRepository refreshTokens;
    private final LoginAttemptRepository loginAttempts;
    private final EmailTokens emailTokens;
    private final AuthEmails authEmails;
    private final PasswordEncoder passwordEncoder;
    private final Clock clock;

    PasswordResetService(
            AccountRepository accounts,
            RefreshTokenRepository refreshTokens,
            LoginAttemptRepository loginAttempts,
            EmailTokens emailTokens,
            AuthEmails authEmails,
            PasswordEncoder passwordEncoder,
            Clock clock) {
        this.accounts = accounts;
        this.refreshTokens = refreshTokens;
        this.loginAttempts = loginAttempts;
        this.emailTokens = emailTokens;
        this.authEmails = authEmails;
        this.passwordEncoder = passwordEncoder;
        this.clock = clock;
    }

    // Says nothing back: whether the account exists or hit the limit stays hidden.
    @Transactional
    public void forgot(String email) {
        accounts.lockByEmail(AuthService.normalize(email))
                .filter(Account::isActive)
                .ifPresent(account -> emailTokens
                        .issueThrottled(account.getId(), EmailToken.Purpose.RESET_PASSWORD)
                        .ifPresent(token -> authEmails.resetPassword(account, token)));
    }

    // Opening the link proves the inbox is theirs, so it also verifies the email.
    // Every session is closed: whoever knew the old password may be logged in.
    // The email lock goes too, so someone locking the account on purpose cannot keep the owner out.
    // The IP counter stays: it protects other accounts.
    @Transactional
    public void reset(String token, String newPassword) {
        var accountId = emailTokens.consume(token, EmailToken.Purpose.RESET_PASSWORD);
        var account = accounts.findById(accountId).filter(Account::isActive).orElseThrow(AuthException::invalidLink);
        var now = clock.instant();
        account.changePassword(passwordEncoder.encode(newPassword), now);
        account.markEmailVerified(now);
        refreshTokens.revokeAccount(accountId, now);
        loginAttempts.deleteById(LoginAttempt.emailKey(account.getEmail()));
        authEmails.passwordChanged(account);
    }
}
