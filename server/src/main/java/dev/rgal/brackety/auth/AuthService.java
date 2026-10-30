package dev.rgal.brackety.auth;

import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.AuthEmails;
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
import dev.rgal.brackety.common.crypto.Sha256;
import java.time.Clock;
import java.time.LocalDate;
import java.time.Period;
import java.util.List;
import java.util.Optional;
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
        checkMinimumAge(request.birthDate());
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
        if (!account.tryMarkAlreadyRegisteredSent(clock.instant(), EmailTokens.RESEND_INTERVAL)) {
            return;
        }
        if (account.isActive()) {
            authEmails.alreadyRegistered(account);
        } else {
            authEmails.registeredWhilePendingDeletion(account);
        }
    }

    public void checkMinimumAge(LocalDate birthDate) {
        if (Period.between(birthDate, LocalDate.now(clock)).getYears() < MIN_AGE) {
            throw AuthException.underage();
        }
    }

    /** The account with its first profile and consents; {@code passwordHash} is null for a provider sign-up. */
    @Transactional
    public Account createAccount(String email, String passwordHash, RegistrationDetails details) {
        var now = clock.instant();
        var account = accounts.save(new Account(email, passwordHash, details.birthDate(), details.locale(), now));
        profiles.save(new Profile(account.getId(), details.profile(), now));
        consents.saveAll(List.of(
                new Consent(account.getId(), Consent.Document.TERMS, details.acceptedTermsVersion(), now),
                new Consent(account.getId(), Consent.Document.PRIVACY, details.acceptedPrivacyVersion(), now)));
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
        var now = clock.instant();
        var normalizedEmail = Account.normalizeEmail(email);
        var emailAttempt = lockAttempt(LoginAttempt.emailKey(normalizedEmail));
        var ipAttempt = lockAttempt("ip:" + Sha256.hex(clientIp));
        ipAttempt.setIp(clientIp);
        if (emailAttempt.isLocked(now)) {
            throw AuthException.locked(emailAttempt.getLockId());
        }
        if (ipAttempt.isLocked(now)) {
            throw AuthException.locked(ipAttempt.getLockId());
        }
        var account = accounts.findByEmail(normalizedEmail);
        account.ifPresent(a -> emailAttempt.setAccountId(a.getId()));
        if (!passwordMatches(account, password)) {
            // recordFailure is true only for the failure that locks, so each lock sends one email.
            if (emailAttempt.recordFailure(now, LoginAttempt.MAX_EMAIL_FAILURES) && account.isPresent()) {
                authEmails.accountLocked(account.get(), emailAttempt.getLockId());
            }
            ipAttempt.recordFailure(now, LoginAttempt.MAX_IP_FAILURES);
            return Optional.empty();
        }
        // The IP counter is not reset: one valid account must not unlock guessing others from the same IP.
        emailAttempt.reset();
        return account;
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
