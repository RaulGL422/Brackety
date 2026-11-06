package dev.rgal.brackety.auth.session;

import dev.rgal.brackety.auth.session.SessionService.Session;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * The pair each refresh issued, by the hash of the token it rotated, kept in memory only for the reuse grace: a
 * client that lost the answer (flaky wifi) and repeats the refresh gets the same pair. The database only has hashes,
 * so the new refresh token cannot be read back from it; a restart forgets this and the repeat gets a 401 again.
 */
class RecentRefreshes {

    record Issued(Session session, Instant at) {}

    private final Map<String, Issued> byRotatedHash = new ConcurrentHashMap<>();
    private final Duration keep;

    RecentRefreshes(Duration keep) {
        this.keep = keep;
    }

    void put(String rotatedHash, Session session, Instant now) {
        byRotatedHash.values().removeIf(issued -> issued.at().isBefore(now.minus(keep)));
        byRotatedHash.put(rotatedHash, new Issued(session, now));
    }

    Optional<Issued> get(String rotatedHash, Instant now) {
        return Optional.ofNullable(byRotatedHash.get(rotatedHash))
                .filter(issued -> !issued.at().isBefore(now.minus(keep)));
    }
}
