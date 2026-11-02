package dev.rgal.brackety.auth.me;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.ConsentRepository;
import dev.rgal.brackety.auth.account.IdentityRepository;
import dev.rgal.brackety.auth.account.ProfileRepository;
import dev.rgal.brackety.auth.dto.DataExport;
import dev.rgal.brackety.auth.dto.DataExport.AccountData;
import dev.rgal.brackety.auth.dto.DataExport.ConsentData;
import dev.rgal.brackety.auth.dto.DataExport.IdentityData;
import dev.rgal.brackety.auth.dto.DataExport.ProfileData;
import java.time.Clock;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Right of access and portability (doc 06).
@Service
class DataExportService {

    private final AccountRepository accounts;
    private final ProfileRepository profiles;
    private final IdentityRepository identities;
    private final ConsentRepository consents;
    private final Clock clock;

    DataExportService(
            AccountRepository accounts,
            ProfileRepository profiles,
            IdentityRepository identities,
            ConsentRepository consents,
            Clock clock) {
        this.accounts = accounts;
        this.profiles = profiles;
        this.identities = identities;
        this.consents = consents;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    DataExport export(UUID accountId) {
        var account = accounts.findById(accountId).filter(Account::isActive).orElseThrow(AuthException::invalidSession);
        return new DataExport(
                clock.instant(),
                new AccountData(
                        account.getEmail(),
                        account.isEmailVerified(),
                        account.hasPassword(),
                        account.getBirthDate(),
                        account.getLocale(),
                        account.getCreatedAt(),
                        account.getUpdatedAt()),
                profiles.findByAccountId(accountId).stream()
                        .map(p -> new ProfileData(
                                p.getType(), p.isValidated(), p.getOrganizationName(), p.getTaxId(), p.getCreatedAt()))
                        .toList(),
                identities.findByAccountIdOrderByCreatedAt(accountId).stream()
                        .map(i -> new IdentityData(i.getProvider().name(), i.getProviderEmail(), i.getLinkedAt()))
                        .toList(),
                consents.findByAccountId(accountId).stream()
                        .map(c -> new ConsentData(c.getDocument().name(), c.getVersion(), c.getAcceptedAt()))
                        .toList());
    }
}
