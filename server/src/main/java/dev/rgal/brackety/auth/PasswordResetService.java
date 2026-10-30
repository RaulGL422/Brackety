package dev.rgal.brackety.auth;

import java.time.Clock;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PasswordResetService {

    private final AccountRepository accounts;
    private final RefreshTokenRepository refreshTokens;
    private final EmailTokens emailTokens;
    private final AuthEmails authEmails;
    private final PasswordEncoder passwordEncoder;
    private final Clock clock;

    PasswordResetService(
            AccountRepository accounts,
            RefreshTokenRepository refreshTokens,
            EmailTokens emailTokens,
            AuthEmails authEmails,
            PasswordEncoder passwordEncoder,
            Clock clock) {
        this.accounts = accounts;
        this.refreshTokens = refreshTokens;
        this.emailTokens = emailTokens;
        this.authEmails = authEmails;
        this.passwordEncoder = passwordEncoder;
        this.clock = clock;
    }

    // Says nothing back: whether the account exists or hit the limit stays hidden.
    @Transactional
    public void forgot(String email) {
        accounts.findByEmail(AuthService.normalize(email))
                .filter(Account::isActive)
                .ifPresent(account -> emailTokens
                        .issueThrottled(account.getId(), EmailToken.Purpose.RESET_PASSWORD)
                        .ifPresent(token -> authEmails.resetPassword(account, token)));
    }

    // Opening the link proves the inbox is theirs, so it also verifies the email.
    // Every session is closed: whoever knew the old password may be logged in.
    @Transactional
    public void reset(String token, String newPassword) {
        var accountId = emailTokens.consume(token, EmailToken.Purpose.RESET_PASSWORD);
        var account = accounts.findById(accountId).filter(Account::isActive).orElseThrow(AuthException::invalidLink);
        var now = clock.instant();
        account.changePassword(passwordEncoder.encode(newPassword), now);
        account.markEmailVerified(now);
        refreshTokens.revokeAccount(accountId, now);
        authEmails.passwordChanged(account);
    }
}
