package dev.rgal.brackety.auth.google;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.Identity;
import dev.rgal.brackety.auth.account.IdentityRepository;
import dev.rgal.brackety.auth.dto.RegistrationDetails;
import dev.rgal.brackety.auth.google.GoogleIdTokens.GoogleUser;
import dev.rgal.brackety.auth.session.SessionService;
import dev.rgal.brackety.auth.session.SessionService.Session;
import java.time.Clock;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class GoogleSignInService {

    private final GoogleIdTokens googleTokens;
    private final IdentityRepository identities;
    private final AccountRepository accounts;
    private final AuthService auth;
    private final SessionService sessions;
    private final Clock clock;

    GoogleSignInService(
            GoogleIdTokens googleTokens,
            IdentityRepository identities,
            AccountRepository accounts,
            AuthService auth,
            SessionService sessions,
            Clock clock) {
        this.googleTokens = googleTokens;
        this.identities = identities;
        this.accounts = accounts;
        this.auth = auth;
        this.sessions = sessions;
        this.clock = clock;
    }

    @Transactional
    public Result signIn(String idToken, RegistrationDetails registration) {
        var google = googleTokens.verify(idToken);
        var identity = identities.findByProviderAndSubject(Identity.Provider.GOOGLE, google.subject());
        if (identity.isPresent()) {
            // Past the grace a deleted account is as if gone, until the purge removes it.
            var account = accounts.findById(identity.get().getAccountId())
                    .filter(a -> a.isActive() || a.isRestorable(clock.instant()))
                    .orElseThrow(AuthException::googleSignInFailed);
            if (!account.isActive()) {
                throw auth.pendingDeletion(account);
            }
            return Result.signedIn(sessions.start(account), false);
        }
        var existing = accounts.lockByEmail(google.email());
        // Never merged on its own: the owner links Google from settings once signed in.
        // A deleted account keeps its email until purged, so its owner can still restore it.
        if (existing.isPresent()
                && (existing.get().isEmailVerified() || !existing.get().isActive())) {
            throw AuthException.accountExists();
        }
        // Google has proved the email is theirs, so it can be told back.
        if (registration == null) {
            return Result.registrationRequired(google.email());
        }
        auth.checkRegistration(registration);
        existing.ifPresent(this::deleteUnverified);
        var account = register(google, registration);
        return Result.signedIn(sessions.start(account), existing.isPresent());
    }

    // Whoever signed up with a password never proved the inbox was theirs; the Google user has.
    // Profiles, consents, tokens and sessions go with it (on delete cascade).
    private void deleteUnverified(Account unverified) {
        accounts.delete(unverified);
        // Hibernate runs inserts before deletes: without this the new account would clash on the email.
        accounts.flush();
    }

    private Account register(GoogleUser google, RegistrationDetails registration) {
        var now = clock.instant();
        var account = auth.createAccount(google.email(), null, registration);
        account.markEmailVerified(now);
        identities.save(new Identity(account.getId(), Identity.Provider.GOOGLE, google.subject(), google.email(), now));
        return account;
    }

    /** A session, or (session null) the email to show while the app asks for the registration details. */
    public record Result(Session session, String registrationEmail, boolean replacedUnverifiedAccount) {

        static Result signedIn(Session session, boolean replacedUnverifiedAccount) {
            return new Result(session, null, replacedUnverifiedAccount);
        }

        static Result registrationRequired(String email) {
            return new Result(null, email, false);
        }
    }
}
