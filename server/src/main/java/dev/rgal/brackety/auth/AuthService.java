package dev.rgal.brackety.auth;

import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.AuthEmails;
import dev.rgal.brackety.auth.account.Cif;
import dev.rgal.brackety.auth.account.Consent;
import dev.rgal.brackety.auth.account.ConsentRepository;
import dev.rgal.brackety.auth.account.Profile;
import dev.rgal.brackety.auth.account.ProfileRepository;
import dev.rgal.brackety.auth.dto.RegisterRequest;
import dev.rgal.brackety.auth.dto.RegistrationDetails;
import dev.rgal.brackety.auth.email.EmailToken;
import dev.rgal.brackety.auth.email.EmailTokens;
import dev.rgal.brackety.auth.lockout.LoginAttempt;
import dev.rgal.brackety.auth.lockout.LoginAttemptRepository;
import dev.rgal.brackety.auth.session.SessionService;
import dev.rgal.brackety.auth.session.SessionService.Session;
import dev.rgal.brackety.auth.session.ShortLivedTokens;
import java.time.Clock;
import java.time.LocalDate;
import java.time.Period;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.function.BooleanSupplier;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    static final int MIN_AGE = 14;

    private final AccountRepository accounts;
    private final ProfileRepository profiles;
    private final ConsentRepository consents;
    private final LoginAttemptRepository loginAttempts;
    private final SessionService sessions;
    private final ShortLivedTokens shortLivedTokens;
    private final EmailTokens emailTokens;
    private final AuthEmails authEmails;
    private final PasswordEncoder passwordEncoder;
    private final Clock clock;
    private final String dummyHash;

    AuthService(
            AccountRepository accounts,
            ProfileRepository profiles,
            ConsentRepository consents,
            LoginAttemptRepository loginAttempts,
            SessionService sessions,
            ShortLivedTokens shortLivedTokens,
            EmailTokens emailTokens,
            AuthEmails authEmails,
            PasswordEncoder passwordEncoder,
            Clock clock) {
        this.accounts = accounts;
        this.profiles = profiles;
        this.consents = consents;
        this.loginAttempts = loginAttempts;
        this.sessions = sessions;
        this.shortLivedTokens = shortLivedTokens;
        this.emailTokens = emailTokens;
        this.authEmails = authEmails;
        this.passwordEncoder = passwordEncoder;
        this.clock = clock;
        // Checked against when the account does not exist, so the response time does not reveal it.
        this.dummyHash = passwordEncoder.encode("timing-equaliser-password");
    }

    @Transactional
    public void register(RegisterRequest request) {
        checkRegistration(request.details());
        var email = Account.normalizeEmail(request.email());
        // Hashed before the duplicate check so both paths take the same time.
        var passwordHash = passwordEncoder.encode(request.password());
        var existing = accounts.lockByEmail(email);
        if (existing.isPresent()) {
            notifyAlreadyRegistered(existing.get());
            return;
        }
        var account = createAccount(email, passwordHash, request.details());
        authEmails.verifyEmail(account, emailTokens.issue(account.getId(), EmailToken.Purpose.VERIFY_EMAIL));
    }

    private void notifyAlreadyRegistered(Account account) {
        // Past the grace a deleted account is as if gone, even before the purge removes it: nobody is told.
        if (!account.isActive() && !account.isRestorable(clock.instant())) {
            return;
        }
        if (!account.tryMarkAlreadyRegisteredSent(clock.instant(), EmailTokens.RESEND_INTERVAL)) {
            return;
        }
        if (account.isActive()) {
            authEmails.alreadyRegistered(account);
        } else {
            authEmails.registeredWhilePendingDeletion(account);
        }
    }

    /** The rules Bean Validation cannot check: the organizer's CIF, or the minimum age of everyone else. */
    public void checkRegistration(RegistrationDetails details) {
        if (details.isOrganizer()) {
            if (!Cif.isValid(details.organization().taxId())) {
                throw AuthException.invalidTaxId();
            }
        } else if (Period.between(details.birthDate(), LocalDate.now(clock)).getYears() < MIN_AGE) {
            throw AuthException.underage();
        }
    }

    /**
     * The account with its first profile and consents, after {@link #checkRegistration}; {@code passwordHash} is null
     * for a provider sign-up.
     */
    @Transactional
    public Account createAccount(String email, String passwordHash, RegistrationDetails details) {
        var now = clock.instant();
        var account = accounts.save(new Account(email, passwordHash, details.birthDate(), details.locale(), now));
        var organization = details.organization();
        profiles.save(
                organization == null
                        ? new Profile(account.getId(), details.profile(), now)
                        : new Profile(
                                account.getId(), details.profile(), organization.name(), organization.taxId(), now));
        var accepted = new ArrayList<>(List.of(
                new Consent(account.getId(), Consent.Document.TERMS, details.acceptedTermsVersion(), now),
                new Consent(account.getId(), Consent.Document.PRIVACY, details.acceptedPrivacyVersion(), now)));
        if (details.isOrganizer()) {
            accepted.add(new Consent(
                    account.getId(), Consent.Document.ORGANIZER_DECLARATION, details.acceptedTermsVersion(), now));
        }
        consents.saveAll(accepted);
        return account;
    }

    // No rollback on AuthException: the failure counters must be saved even though the login fails.
    @Transactional(noRollbackFor = AuthException.class)
    public Session login(String email, String password, String clientIp) {
        var account = checkPassword(email, password, clientIp)
                .filter(a -> a.isActive() || a.isRestorable(clock.instant()))
                .orElseThrow(AuthException::invalidCredentials);
        if (!account.isActive()) {
            throw pendingDeletion(account);
        }
        return sessions.start(account);
    }

    /** For a deleted account whose owner has just proved it is theirs: when it goes, and how to keep it. */
    public AuthException pendingDeletion(Account account) {
        return AuthException.pendingDeletion(
                account.deletesOn(clock.getZone()),
                shortLivedTokens.issue(account.getId(), ShortLivedTokens.Purpose.RESTORE));
    }

    // Issued after the deletion, so the session cut does not apply; past the grace the account is as if gone.
    @Transactional
    public Session restore(String restoreToken) {
        var now = clock.instant();
        var account = shortLivedTokens
                .verify(restoreToken, ShortLivedTokens.Purpose.RESTORE)
                .flatMap(token -> accounts.lockById(token.accountId()))
                .filter(a -> a.isRestorable(now))
                .orElseThrow(AuthException::invalidSession);
        account.restore(now);
        return sessions.start(account);
    }

    /**
     * The account (deleted ones too) if the password is right; empty if not, after counting the failure.
     * Throws 429 while the email or IP is locked. The caller's transaction must not roll back on
     * AuthException, or the counters are lost.
     */
    @Transactional(noRollbackFor = AuthException.class)
    public Optional<Account> checkPassword(String email, String password, String clientIp) {
        var normalizedEmail = Account.normalizeEmail(email);
        var account = accounts.findByEmail(normalizedEmail);
        var matches = underLockout(
                LoginAttempt.emailKey(normalizedEmail), account, clientIp, () -> passwordMatches(account, password));
        return matches ? account : Optional.empty();
    }

    /**
     * For the superadmin login: runs {@code check} with the user login rules (5 failures in 15 min lock 15 min)
     * on the superadmin own counter, plus the IP counter it shares with the user login. 429 while locked; a false
     * result counts as a failure. Same transaction rule as {@link #checkPassword}.
     */
    @Transactional(noRollbackFor = AuthException.class)
    public boolean checkSuperadminUnderLockout(String clientIp, BooleanSupplier check) {
        return underLockout(LoginAttempt.ADMIN_KEY, Optional.empty(), clientIp, check);
    }

    private boolean underLockout(String key, Optional<Account> account, String clientIp, BooleanSupplier check) {
        var now = clock.instant();
        var keyAttempt = lockAttempt(key);
        var ipAttempt = lockAttempt(LoginAttempt.ipKey(clientIp));
        ipAttempt.setIp(clientIp);
        if (keyAttempt.isLocked(now)) {
            throw AuthException.locked(keyAttempt.getLockId());
        }
        if (ipAttempt.isLocked(now)) {
            throw AuthException.locked(ipAttempt.getLockId());
        }
        account.ifPresent(a -> keyAttempt.setAccountId(a.getId()));
        if (!check.getAsBoolean()) {
            // recordFailure is true only for the failure that locks, so each lock sends one email.
            if (keyAttempt.recordFailure(now, LoginAttempt.MAX_EMAIL_FAILURES) && account.isPresent()) {
                authEmails.accountLocked(account.get(), keyAttempt.getLockId());
            }
            ipAttempt.recordFailure(now, LoginAttempt.MAX_IP_FAILURES);
            return false;
        }
        // The IP counter is not reset: one valid account must not unlock guessing others from the same IP.
        keyAttempt.reset();
        return true;
    }

    private LoginAttempt lockAttempt(String key) {
        loginAttempts.createIfMissing(key);
        return loginAttempts.lockByKey(key);
    }

    private boolean passwordMatches(Optional<Account> account, String password) {
        var hash = account.map(Account::getPasswordHash).orElse(null);
        if (hash == null) {
            passwordEncoder.matches(password, dummyHash);
            return false;
        }
        return passwordEncoder.matches(password, hash);
    }
}
