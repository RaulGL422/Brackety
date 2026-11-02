package dev.rgal.brackety.auth.email;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.common.crypto.RandomTokens;
import dev.rgal.brackety.common.crypto.Sha256;
import java.time.Clock;
import java.time.Duration;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Component;

// Single-use links sent by email. Only the hash is stored: a database leak gives no usable link.
@Component
public class EmailTokens {

    public static final Duration RESEND_INTERVAL = Duration.ofSeconds(60);

    private final EmailTokenRepository tokens;
    private final Clock clock;

    EmailTokens(EmailTokenRepository tokens, Clock clock) {
        this.tokens = tokens;
        this.clock = clock;
    }

    /** Replaces any earlier token of the same purpose and returns the raw one, to send by email. */
    public String issue(UUID accountId, EmailToken.Purpose purpose) {
        return issue(accountId, purpose, null);
    }

    private String issue(UUID accountId, EmailToken.Purpose purpose, String newEmail) {
        tokens.deleteByAccountIdAndPurpose(accountId, purpose);
        var raw = RandomTokens.newToken();
        tokens.save(new EmailToken(Sha256.hex(raw), accountId, purpose, newEmail, clock.instant()));
        return raw;
    }

    /** Like {@link #issue} but empty if one was issued in the last minute, so nobody can flood an inbox. */
    Optional<String> issueThrottled(UUID accountId, EmailToken.Purpose purpose) {
        return issueThrottled(accountId, purpose, null);
    }

    /** {@code newEmail} is only for {@code CHANGE_EMAIL}: the address the link confirms. */
    Optional<String> issueThrottled(UUID accountId, EmailToken.Purpose purpose, String newEmail) {
        var since = clock.instant().minus(RESEND_INTERVAL);
        if (tokens.existsByAccountIdAndPurposeAndCreatedAtAfter(accountId, purpose, since)) {
            return Optional.empty();
        }
        return Optional.of(issue(accountId, purpose, newEmail));
    }

    /** Drops every pending link of the account, whatever its purpose. */
    public void deleteAll(UUID accountId) {
        tokens.deleteByAccountId(accountId);
    }

    /** Deletes the token and returns its account; invalid, expired and used tokens fail alike. */
    UUID consume(String raw, EmailToken.Purpose purpose) {
        return take(raw, purpose).getAccountId();
    }

    EmailChange consumeEmailChange(String raw) {
        var token = take(raw, EmailToken.Purpose.CHANGE_EMAIL);
        return new EmailChange(token.getAccountId(), token.getNewEmail());
    }

    /** Like {@link #consume} but leaves the token as it is. */
    UUID check(String raw, EmailToken.Purpose purpose) {
        return find(raw, purpose).getAccountId();
    }

    private EmailToken find(String raw, EmailToken.Purpose purpose) {
        var now = clock.instant();
        return tokens.findByTokenHash(Sha256.hex(raw))
                .filter(t -> t.isUsable(purpose, now))
                .orElseThrow(AuthException::invalidLink);
    }

    private EmailToken take(String raw, EmailToken.Purpose purpose) {
        var token = find(raw, purpose);
        // Deleted under the row lock: a concurrent second use waits, then finds nothing.
        tokens.delete(token);
        return token;
    }

    record EmailChange(UUID accountId, String newEmail) {}
}
