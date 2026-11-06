package dev.rgal.brackety.demo;

import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.Profile;
import dev.rgal.brackety.auth.account.ProfileRepository;
import dev.rgal.brackety.auth.account.ProfileType;
import java.time.Clock;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Accounts whose password is their username, already verified (docs/modulos/prototipo-f1.md): the demo ones and
 * the staff an event package brings (docs/modulos/servidor-local.md).
 */
@Component
public class DemoAccounts {

    private final AccountRepository accounts;
    private final ProfileRepository profiles;
    private final PasswordEncoder passwordEncoder;
    private final Clock clock;

    DemoAccounts(AccountRepository accounts, ProfileRepository profiles, PasswordEncoder passwordEncoder, Clock clock) {
        this.accounts = accounts;
        this.profiles = profiles;
        this.passwordEncoder = passwordEncoder;
        this.clock = clock;
    }

    /** A helper's account, created if missing. */
    public UUID helper(String username) {
        return findOrCreate(username, ProfileType.HELPER, null, null);
    }

    /** An organizer's account with a club profile, created if missing; the organization may be unknown. */
    public UUID club(String username, String organizationName, String taxId) {
        return findOrCreate(username, ProfileType.CLUB, organizationName, taxId);
    }

    private UUID findOrCreate(String username, ProfileType profile, String organizationName, String taxId) {
        var existing = accounts.findByEmail(username);
        if (existing.isPresent()) {
            return existing.get().getId();
        }
        var now = clock.instant();
        var birthDate = profile.isOrganizer() ? null : LocalDate.now(clock).minusYears(30);
        var account = new Account(username, passwordEncoder.encode(username), birthDate, "es", now);
        account.markEmailVerified(now);
        accounts.save(account);
        profiles.save(
                profile.isOrganizer()
                        ? new Profile(account.getId(), profile, organizationName, taxId, now)
                        : new Profile(account.getId(), profile, now));
        return account.getId();
    }
}
