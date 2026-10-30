package dev.rgal.brackety.auth.reauth;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.Identity;
import dev.rgal.brackety.auth.account.IdentityRepository;
import dev.rgal.brackety.auth.dto.ReauthRequest;
import dev.rgal.brackety.auth.dto.ReauthResponse;
import dev.rgal.brackety.auth.google.GoogleIdTokens;
import dev.rgal.brackety.auth.session.ShortLivedTokens;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// A stolen access token alone must not be enough to delete, export or take over the account.
@Service
public class ReauthService {

    public static final String HEADER = "X-Reauth";

    private final AccountRepository accounts;
    private final IdentityRepository identities;
    private final AuthService auth;
    private final GoogleIdTokens googleTokens;
    private final ShortLivedTokens shortLivedTokens;

    ReauthService(
            AccountRepository accounts,
            IdentityRepository identities,
            AuthService auth,
            GoogleIdTokens googleTokens,
            ShortLivedTokens shortLivedTokens) {
        this.accounts = accounts;
        this.identities = identities;
        this.auth = auth;
        this.googleTokens = googleTokens;
        this.shortLivedTokens = shortLivedTokens;
    }

    // No rollback on AuthException: a wrong password counts towards the login lock, as in a login.
    @Transactional(noRollbackFor = AuthException.class)
    ReauthResponse reauthenticate(UUID accountId, ReauthRequest request, String clientIp) {
        var account = accounts.findById(accountId).filter(Account::isActive).orElseThrow(AuthException::invalidSession);
        var proved = request.password() != null
                ? auth.checkPassword(account.getEmail(), request.password(), clientIp)
                        .filter(a -> a.getId().equals(accountId))
                        .isPresent()
                : ownsGoogleAccount(accountId, request.googleIdToken());
        if (!proved) {
            throw AuthException.reauthFailed();
        }
        return new ReauthResponse(
                shortLivedTokens.issue(accountId, ShortLivedTokens.Purpose.REAUTH), ShortLivedTokens.TTL.toSeconds());
    }

    /** Throws 403 {@code REAUTH_REQUIRED} unless {@code token} is a live reauth token of this account. */
    public void require(UUID accountId, String token) {
        shortLivedTokens
                .verify(token, ShortLivedTokens.Purpose.REAUTH)
                .filter(accountId::equals)
                .orElseThrow(AuthException::reauthRequired);
    }

    private boolean ownsGoogleAccount(UUID accountId, String idToken) {
        var google = googleTokens.verify(idToken);
        return identities
                .findByProviderAndSubject(Identity.Provider.GOOGLE, google.subject())
                .filter(i -> i.getAccountId().equals(accountId))
                .isPresent();
    }
}
