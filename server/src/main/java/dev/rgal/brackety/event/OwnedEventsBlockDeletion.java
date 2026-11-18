package dev.rgal.brackety.event;

import dev.rgal.brackety.auth.me.AccountDeletionBlocker;
import java.util.UUID;
import org.springframework.stereotype.Component;

/** An owned event is never left without owner. */
@Component
class OwnedEventsBlockDeletion implements AccountDeletionBlocker {

    private final EventRepository events;

    OwnedEventsBlockDeletion(EventRepository events) {
        this.events = events;
    }

    @Override
    public boolean blocksDeletion(UUID accountId) {
        return events.existsByOwnerAccountId(accountId);
    }
}
