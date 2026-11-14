package dev.rgal.brackety.event;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

/**
 * After the event's mats change (one more or less, a referee, a mat out of use), which referees have not loaded their
 * board since (Raul, 2026-11-14: "estuvimos un ratito esperando"). Every board says so for a minute at most, so
 * nobody waits without knowing for whom. In memory: after a restart there is nothing to wait for.
 */
@Component
public class MatSync {

    static final Duration WINDOW = Duration.ofSeconds(60);

    private final Map<UUID, Instant> changed = new ConcurrentHashMap<>();
    private final Map<UUID, Instant> seen = new ConcurrentHashMap<>();
    private final Clock clock;

    MatSync(Clock clock) {
        this.clock = clock;
    }

    /** From when the change is committed: a board loaded before that does not have it yet. */
    public void changed(UUID eventId) {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    changed.put(eventId, clock.instant());
                }
            });
        } else {
            changed.put(eventId, clock.instant());
        }
    }

    /** The mat's referee has just loaded its board. */
    public void seen(UUID matId) {
        seen.put(matId, clock.instant());
    }

    /** The numbers of the event's mats with a referee whose board has not loaded since the change; empty after a minute. */
    public List<Integer> waitingFor(UUID eventId, List<Mat> mats) {
        var at = changed.get(eventId);
        if (at == null || clock.instant().isAfter(at.plus(WINDOW))) {
            return List.of();
        }
        return mats.stream()
                .filter(m -> m.getRefereeAccountId() != null)
                .filter(m -> seen.getOrDefault(m.getId(), Instant.MIN).isBefore(at))
                .map(Mat::getNumber)
                .toList();
    }
}
