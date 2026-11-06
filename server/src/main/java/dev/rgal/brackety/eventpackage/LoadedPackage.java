package dev.rgal.brackety.eventpackage;

import java.util.List;
import java.util.UUID;

/** The event a package created and the staff accounts that did not exist, with their new passwords. */
record LoadedPackage(UUID eventId, List<NewAccount> newAccounts) {

    /** {@code roles} and {@code mats} comma separated; mats empty if they referee none. */
    record NewAccount(String username, String roles, String password, String mats) {}
}
