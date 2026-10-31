package dev.rgal.brackety.auth.admin;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.AuthEmails;
import dev.rgal.brackety.auth.account.Profile;
import dev.rgal.brackety.auth.account.ProfileRepository;
import dev.rgal.brackety.auth.account.ProfileType;
import java.time.Clock;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class AdminOrganizerService {

    private static final List<ProfileType> ORGANIZER_TYPES = List.of(ProfileType.CLUB, ProfileType.EXTERNAL_ENTITY);

    private final ProfileRepository profiles;
    private final AccountRepository accounts;
    private final AuthEmails authEmails;
    private final AdminAuditRepository audit;
    private final Clock clock;

    AdminOrganizerService(
            ProfileRepository profiles,
            AccountRepository accounts,
            AuthEmails authEmails,
            AdminAuditRepository audit,
            Clock clock) {
        this.profiles = profiles;
        this.accounts = accounts;
        this.authEmails = authEmails;
        this.audit = audit;
        this.clock = clock;
    }

    /** Organizer profiles of active accounts, oldest first; {@code validated} null = all. */
    @Transactional(readOnly = true)
    public List<OrganizerResponse> list(Boolean validated) {
        var organizers = profiles.findByTypeIn(ORGANIZER_TYPES).stream()
                .filter(p -> validated == null || p.isValidated() == validated)
                .toList();
        var accountIds = organizers.stream().map(Profile::getAccountId).collect(Collectors.toSet());
        Map<UUID, Account> active = accounts.findAllById(accountIds).stream()
                .filter(Account::isActive)
                .collect(Collectors.toMap(Account::getId, Function.identity()));
        return organizers.stream()
                .filter(p -> active.containsKey(p.getAccountId()))
                .sorted(Comparator.comparing(Profile::getCreatedAt))
                .map(p -> new OrganizerResponse(
                        p.getAccountId(),
                        active.get(p.getAccountId()).getEmail(),
                        p.getType(),
                        p.isValidated(),
                        p.getCreatedAt()))
                .toList();
    }

    /** Idempotent: an organizer already validated is not emailed or audited again. */
    @Transactional
    public void validate(UUID accountId) {
        // Row lock: two validations at once would both see the profile pending and email twice.
        var account = accounts.lockById(accountId).filter(Account::isActive).orElseThrow(AuthException::notFound);
        var organizers = profiles.findByAccountId(accountId).stream()
                .filter(Profile::isOrganizer)
                .toList();
        if (organizers.isEmpty()) {
            throw AuthException.notFound();
        }
        var now = clock.instant();
        for (var profile : organizers) {
            if (profile.validate()) {
                authEmails.organizerValidated(account, profile.getType());
                audit.save(new AdminAudit(AdminAudit.Action.ORGANIZER_VALIDATED, accountId.toString(), now));
            }
        }
    }

    /** {@code createdAt} is when the account took the organizer profile. */
    record OrganizerResponse(
            UUID accountId, String email, ProfileType profileType, boolean validated, Instant createdAt) {}
}
