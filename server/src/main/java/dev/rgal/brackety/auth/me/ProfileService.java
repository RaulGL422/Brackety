package dev.rgal.brackety.auth.me;

import static dev.rgal.brackety.auth.account.ProfileType.EXTERNAL;
import static dev.rgal.brackety.auth.account.ProfileType.HELPER;
import static dev.rgal.brackety.auth.account.ProfileType.STUDENT;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.Profile;
import dev.rgal.brackety.auth.account.ProfileRepository;
import dev.rgal.brackety.auth.account.ProfileType;
import java.time.Clock;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// docs/roles/README.md: any single profile, or Helper with Student or with External. Club and External
// Entity are organizers and combine with nothing; External is never a Student.
// Each change takes the account row lock, so two at once cannot end in a forbidden combination.
@Service
class ProfileService {

    private static final List<Set<ProfileType>> ALLOWED_PAIRS =
            List.of(Set.of(STUDENT, HELPER), Set.of(EXTERNAL, HELPER));

    private final AccountRepository accounts;
    private final ProfileRepository profiles;
    private final Clock clock;

    ProfileService(AccountRepository accounts, ProfileRepository profiles, Clock clock) {
        this.accounts = accounts;
        this.profiles = profiles;
        this.clock = clock;
    }

    // A new organizer profile starts unvalidated (the column default), as at sign-up.
    @Transactional
    void add(UUID accountId, ProfileType type) {
        lockActive(accountId);
        var types = new HashSet<ProfileType>();
        profiles.findByAccountId(accountId).forEach(p -> types.add(p.getType()));
        if (!types.add(type)) {
            return;
        }
        // An organizer gives the organization's name and CIF at sign-up; there is no way to give them here.
        if (type.isOrganizer() || !isAllowed(types)) {
            throw AuthException.profileCombinationNotAllowed();
        }
        profiles.save(new Profile(accountId, type, clock.instant()));
    }

    // Any subset of an allowed combination is allowed, so removing only has to keep one profile.
    @Transactional
    void remove(UUID accountId, ProfileType type) {
        lockActive(accountId);
        var current = profiles.findByAccountId(accountId);
        var profile = current.stream().filter(p -> p.getType() == type).findFirst();
        if (profile.isEmpty()) {
            return;
        }
        if (current.size() == 1) {
            throw AuthException.lastProfile();
        }
        profiles.delete(profile.get());
    }

    static boolean isAllowed(Set<ProfileType> types) {
        return types.size() == 1 || ALLOWED_PAIRS.contains(types);
    }

    private void lockActive(UUID accountId) {
        accounts.lockById(accountId).filter(Account::isActive).orElseThrow(AuthException::invalidSession);
    }
}
