package dev.rgal.brackety.auth;

import dev.rgal.brackety.auth.SessionService.Session;
import dev.rgal.brackety.auth.dto.RegisterRequest;
import java.time.Clock;
import java.time.LocalDate;
import java.time.Period;
import java.util.List;
import java.util.Locale;
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
            EmailTokens emailTokens,
            AuthEmails authEmails,
            PasswordEncoder passwordEncoder,
            Clock clock) {
        this.accounts = accounts;
        this.profiles = profiles;
        this.consents = consents;
        this.loginAttempts = loginAttempts;
        this.sessions = sessions;
        this.emailTokens = emailTokens;
        this.authEmails = authEmails;
        this.passwordEncoder = passwordEncoder;
        this.clock = clock;
        // Checked against when the account does not exist, so the response time does not reveal it.
        this.dummyHash = passwordEncoder.encode("timing-equaliser-password");
    }

    @Transactional
    public void register(RegisterRequest request) {
        if (Period.between(request.birthDate(), LocalDate.now(clock)).getYears() < MIN_AGE) {
            throw AuthException.underage();
        }
        var email = normalize(request.email());
        // Hashed before the duplicate check so both paths take the same time.
        var passwordHash = passwordEncoder.encode(request.password());
        var existing = accounts.lockByEmail(email);
        if (existing.isPresent()) {
            if (existing.get().tryMarkAlreadyRegisteredSent(clock.instant(), EmailTokens.RESEND_INTERVAL)) {
                authEmails.alreadyRegistered(existing.get());
            }
            return;
        }
        var now = clock.instant();
        var account = accounts.save(new Account(email, passwordHash, request.birthDate(), request.locale(), now));
        profiles.save(new Profile(account.getId(), request.profile(), now));
        consents.saveAll(List.of(
                new Consent(account.getId(), Consent.Document.TERMS, request.acceptedTermsVersion(), now),
                new Consent(account.getId(), Consent.Document.PRIVACY, request.acceptedPrivacyVersion(), now)));
        authEmails.verifyEmail(account, emailTokens.issue(account.getId(), EmailToken.Purpose.VERIFY_EMAIL));
    }

    // No rollback on AuthException: the failure counters must be saved even though the login fails.
    @Transactional(noRollbackFor = AuthException.class)
    public Session login(String email, String password, String clientIp) {
        var now = clock.instant();
        var normalizedEmail = normalize(email);
        var emailAttempt = lockAttempt(LoginAttempt.emailKey(normalizedEmail));
        var ipAttempt = lockAttempt("ip:" + Sha256.hex(clientIp));
        ipAttempt.setIp(clientIp);
        if (emailAttempt.isLocked(now)) {
            throw AuthException.locked(emailAttempt.getLockId());
        }
        if (ipAttempt.isLocked(now)) {
            throw AuthException.locked(ipAttempt.getLockId());
        }
        var account = accounts.findByEmail(normalizedEmail).filter(Account::isActive);
        account.ifPresent(a -> emailAttempt.setAccountId(a.getId()));
        if (!passwordMatches(account, password)) {
            // recordFailure is true only for the failure that locks, so each lock sends one email.
            if (emailAttempt.recordFailure(now, LoginAttempt.MAX_EMAIL_FAILURES) && account.isPresent()) {
                authEmails.accountLocked(account.get(), emailAttempt.getLockId());
            }
            ipAttempt.recordFailure(now, LoginAttempt.MAX_IP_FAILURES);
            throw AuthException.invalidCredentials();
        }
        // The IP counter is not reset: one valid account must not unlock guessing others from the same IP.
        emailAttempt.reset();
        return sessions.start(account.get());
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

    static String normalize(String email) {
        return email.strip().toLowerCase(Locale.ROOT);
    }
}
