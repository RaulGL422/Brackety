package dev.rgal.brackety.auth.identity;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.AuthEmails;
import dev.rgal.brackety.auth.account.Identity;
import dev.rgal.brackety.auth.account.IdentityRepository;
import dev.rgal.brackety.auth.dto.SignInMethodResponse;
import dev.rgal.brackety.auth.google.GoogleIdTokens;
import dev.rgal.brackety.auth.session.RefreshTokenRepository;
import java.time.Clock;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Every change takes the account row lock, so two at once cannot leave the account without a way in.
@Service
class IdentityService {

    static final String PASSWORD = "PASSWORD";

    private final AccountRepository accounts;
    private final IdentityRepository identities;
    private final GoogleIdTokens googleTokens;
    private final RefreshTokenRepository refreshTokens;
    private final AuthEmails authEmails;
    private final Clock clock;

    IdentityService(
            AccountRepository accounts,
            IdentityRepository identities,
            GoogleIdTokens googleTokens,
            RefreshTokenRepository refreshTokens,
            AuthEmails authEmails,
            Clock clock) {
        this.accounts = accounts;
        this.identities = identities;
        this.googleTokens = googleTokens;
        this.refreshTokens = refreshTokens;
        this.authEmails = authEmails;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    List<SignInMethodResponse> methods(UUID accountId) {
        var account = accounts.findById(accountId).filter(Account::isActive).orElseThrow(AuthException::invalidSession);
        var methods = new ArrayList<SignInMethodResponse>();
        if (account.hasPassword()) {
            methods.add(new SignInMethodResponse(PASSWORD, null, null));
        }
        for (var identity : identities.findByAccountIdOrderByCreatedAt(accountId)) {
            methods.add(new SignInMethodResponse(
                    identity.getProvider().name(), identity.getProviderEmail(), identity.getLinkedAt()));
        }
        return methods;
    }

    // The Google email may differ from the account one: the identity is the sub, not the address.
    @Transactional
    void linkGoogle(UUID accountId, String idToken) {
        var google = googleTokens.verify(idToken);
        var account = lockActive(accountId);
        var owner = identities.findByProviderAndSubject(Identity.Provider.GOOGLE, google.subject());
        if (owner.isPresent()) {
            if (owner.get().getAccountId().equals(accountId)) {
                return;
            }
            throw AuthException.identityInUse();
        }
        if (identities.findByAccountIdOrderByCreatedAt(accountId).stream()
                .anyMatch(i -> i.getProvider() == Identity.Provider.GOOGLE)) {
            throw AuthException.providerAlreadyLinked();
        }
        identities.save(
                new Identity(accountId, Identity.Provider.GOOGLE, google.subject(), google.email(), clock.instant()));
        authEmails.identityLinked(account, Identity.Provider.GOOGLE);
    }

    @Transactional
    void unlinkGoogle(UUID accountId) {
        var account = lockActive(accountId);
        var linked = identities.findByAccountIdOrderByCreatedAt(accountId);
        var google = linked.stream()
                .filter(i -> i.getProvider() == Identity.Provider.GOOGLE)
                .findFirst();
        if (google.isEmpty()) {
            return;
        }
        if (!account.hasPassword() && linked.size() == 1) {
            throw AuthException.lastSignInMethod();
        }
        identities.delete(google.get());
        authEmails.identityUnlinked(account, Identity.Provider.GOOGLE);
    }

    // Every session is closed, as on a password reset: whoever knew the password may be logged in.
    @Transactional
    void removePassword(UUID accountId) {
        var account = lockActive(accountId);
        if (!account.hasPassword()) {
            return;
        }
        if (identities.findByAccountIdOrderByCreatedAt(accountId).isEmpty()) {
            throw AuthException.lastSignInMethod();
        }
        var now = clock.instant();
        account.removePassword(now);
        refreshTokens.revokeAccount(accountId, now);
        authEmails.passwordRemoved(account);
    }

    private Account lockActive(UUID accountId) {
        return accounts.lockById(accountId).filter(Account::isActive).orElseThrow(AuthException::invalidSession);
    }
}
