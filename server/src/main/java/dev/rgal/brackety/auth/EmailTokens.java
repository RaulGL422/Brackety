package dev.rgal.brackety.auth;

import java.security.SecureRandom;
import java.time.Clock;
import java.time.Duration;
import java.util.Base64;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Component;

// Single-use links sent by email. Only the hash is stored: a database leak gives no usable link.
@Component
class EmailTokens {

    static final Duration RESEND_INTERVAL = Duration.ofSeconds(60);

    private final EmailTokenRepository tokens;
    private final Clock clock;
    private final SecureRandom random = new SecureRandom();

    EmailTokens(EmailTokenRepository tokens, Clock clock) {
        this.tokens = tokens;
        this.clock = clock;
    }

    /** Replaces any earlier token of the same purpose and returns the raw one, to send by email. */
    String issue(UUID accountId, EmailToken.Purpose purpose) {
        tokens.deleteByAccountIdAndPurpose(accountId, purpose);
        var bytes = new byte[32];
        random.nextBytes(bytes);
        var raw = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        tokens.save(new EmailToken(Sha256.hex(raw), accountId, purpose, clock.instant()));
        return raw;
    }

    /** Like {@link #issue} but empty if one was issued in the last minute, so nobody can flood an inbox. */
    Optional<String> issueThrottled(UUID accountId, EmailToken.Purpose purpose) {
        var since = clock.instant().minus(RESEND_INTERVAL);
        if (tokens.existsByAccountIdAndPurposeAndCreatedAtAfter(accountId, purpose, since)) {
            return Optional.empty();
        }
        return Optional.of(issue(accountId, purpose));
    }

    /** Marks the token used and returns its account; invalid, expired and used tokens fail alike. */
    UUID consume(String raw, EmailToken.Purpose purpose) {
        var now = clock.instant();
        var token = tokens.findByTokenHash(Sha256.hex(raw))
                .filter(t -> t.isUsable(purpose, now))
                .orElseThrow(AuthException::invalidLink);
        token.markUsed(now);
        return token.getAccountId();
    }
}
