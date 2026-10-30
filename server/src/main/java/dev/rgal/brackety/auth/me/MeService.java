package dev.rgal.brackety.auth.me;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.ProfileRepository;
import dev.rgal.brackety.auth.dto.MeResponse;
import dev.rgal.brackety.auth.dto.ProfileResponse;
import dev.rgal.brackety.auth.identity.IdentityService;
import java.time.Clock;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class MeService {

    private final AccountRepository accounts;
    private final ProfileRepository profiles;
    private final IdentityService identities;
    private final Clock clock;

    MeService(AccountRepository accounts, ProfileRepository profiles, IdentityService identities, Clock clock) {
        this.accounts = accounts;
        this.profiles = profiles;
        this.identities = identities;
        this.clock = clock;
    }

    // A deleted account still answers while its last access token lives, so the app can show the date.
    @Transactional(readOnly = true)
    MeResponse get(UUID accountId) {
        return response(accounts.findById(accountId).orElseThrow(AuthException::invalidSession));
    }

    @Transactional
    MeResponse updateLocale(UUID accountId, String locale) {
        var account = accounts.lockById(accountId).filter(Account::isActive).orElseThrow(AuthException::invalidSession);
        account.changeLocale(locale, clock.instant());
        return response(account);
    }

    private MeResponse response(Account account) {
        var accountProfiles = profiles.findByAccountId(account.getId()).stream()
                .map(p -> new ProfileResponse(p.getType(), p.isValidated()))
                .toList();
        return new MeResponse(
                account.getEmail(),
                account.isEmailVerified(),
                account.getBirthDate(),
                account.getLocale(),
                accountProfiles,
                identities.methods(account),
                account.deletesOn(clock.getZone()));
    }
}
