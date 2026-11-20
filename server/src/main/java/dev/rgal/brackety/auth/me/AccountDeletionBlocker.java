package dev.rgal.brackety.auth.me;

import java.util.UUID;

/**
 * Something an account owns that holds other people's data, so the account cannot be deleted until it is handed over
 * or deleted. Each feature that owns such data implements it; auth does not need to know them.
 */
public interface AccountDeletionBlocker {

    boolean blocksDeletion(UUID accountId);
}
