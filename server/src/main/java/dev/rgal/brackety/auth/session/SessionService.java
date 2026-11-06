package dev.rgal.brackety.auth.session;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.AuthEmails;
import dev.rgal.brackety.auth.account.ProfileRepository;
import dev.rgal.brackety.auth.email.EmailTokens;
import dev.rgal.brackety.common.crypto.RandomTokens;
import dev.rgal.brackety.common.crypto.Sha256;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SessionService {

    static final Duration ACCESS_TTL = Duration.ofMinutes(15);
    public static final Duration REFRESH_TTL = Duration.ofDays(30);
    // Two tabs, two app calls at once or a repeat after a lost answer are not a theft: within this time the
    // repeat gets the same pair the first refresh issued (or a 401 if it can no longer be given).
    static final Duration REUSE_GRACE = Duration.ofSeconds(10);
    public static final String EMAIL_VERIFIED_CLAIM = "email_verified";
    // Tells an access token from the other tokens signed with the same key (see ShortLivedTokens).
    public static final String PURPOSE_CLAIM = "purpose";
    public static final String ACCESS_PURPOSE = "ACCESS";

    private static final Logger log = LoggerFactory.getLogger(SessionService.class);

    private final RefreshTokenRepository refreshTokens;
    private final AccountRepository accounts;
    private final ProfileRepository profiles;
    private final AuthEmails authEmails;
    private final EmailTokens emailTokens;
    private final JwtEncoder jwtEncoder;
    private final Clock clock;
    private final RecentRefreshes recent = new RecentRefreshes(REUSE_GRACE);

    SessionService(
            RefreshTokenRepository refreshTokens,
            AccountRepository accounts,
            ProfileRepository profiles,
            AuthEmails authEmails,
            EmailTokens emailTokens,
            JwtEncoder jwtEncoder,
            Clock clock) {
        this.refreshTokens = refreshTokens;
        this.accounts = accounts;
        this.profiles = profiles;
        this.authEmails = authEmails;
        this.emailTokens = emailTokens;
        this.jwtEncoder = jwtEncoder;
        this.clock = clock;
    }

    @Transactional
    public Session start(Account account) {
        return issue(account, UUID.randomUUID(), clock.instant());
    }

    // No rollback on AuthException: revoking a family on reuse must be committed even though the call fails.
    @Transactional(noRollbackFor = AuthException.class)
    public Session refresh(String rawToken) {
        var now = clock.instant();
        var token = find(rawToken);
        if (token.isRevoked()) {
            throw AuthException.invalidSession();
        }
        if (token.isUsed() && token.wasUsedSince(now.minus(REUSE_GRACE))) {
            return repeat(Sha256.hex(rawToken), token, now).orElseThrow(AuthException::invalidSession);
        }
        if (token.isUsed()) {
            refreshTokens.revokeFamily(token.getFamilyId(), now);
            log.warn("Refresh token reused: session family {} revoked", token.getFamilyId());
            accounts.findById(token.getAccountId()).ifPresent(authEmails::sessionReused);
            throw AuthException.invalidSession();
        }
        var account = accounts.findById(token.getAccountId()).filter(Account::isActive);
        if (token.isExpired(now) || account.isEmpty()) {
            throw AuthException.invalidSession();
        }
        token.markUsed(now);
        var session = issue(account.get(), token.getFamilyId(), now);
        recent.put(Sha256.hex(rawToken), session, now);
        return session;
    }

    // Only while the pair it issued is still the session's latest: never a token the client has already rotated.
    private Optional<Session> repeat(String rotatedHash, RefreshToken rotated, Instant now) {
        return recent.get(rotatedHash, now)
                .filter(issued -> refreshTokens
                        .findByTokenHash(Sha256.hex(issued.session().refreshToken()))
                        .filter(child -> !child.isUsed() && !child.isRevoked() && !child.isExpired(now))
                        .isPresent())
                .filter(issued -> accounts.findById(rotated.getAccountId())
                        .filter(Account::isActive)
                        .isPresent())
                .map(issued -> {
                    var s = issued.session();
                    var left = ACCESS_TTL.minus(Duration.between(issued.at(), now));
                    return new Session(s.accessToken(), left.toSeconds(), s.refreshToken(), s.emailVerified());
                });
    }

    @Transactional
    public void logout(String rawToken) {
        if (rawToken == null || rawToken.isBlank()) {
            return;
        }
        refreshTokens
                .findByTokenHash(Sha256.hex(rawToken))
                .ifPresent(t -> refreshTokens.revokeFamily(t.getFamilyId(), clock.instant()));
    }

    /**
     * For a change of credentials or a deletion: every refresh, access and reauth token of the account stops
     * working, and so do the links already emailed (an attacker's email change, a reset sent to the old address).
     */
    @Transactional
    public void closeAll(Account account) {
        var now = clock.instant();
        refreshTokens.revokeAccount(account.getId(), now);
        account.revokeSessions(now);
        emailTokens.deleteAll(account.getId());
    }

    private RefreshToken find(String rawToken) {
        if (rawToken == null || rawToken.isBlank()) {
            throw AuthException.invalidSession();
        }
        return refreshTokens.findByTokenHash(Sha256.hex(rawToken)).orElseThrow(AuthException::invalidSession);
    }

    private Session issue(Account account, UUID familyId, Instant now) {
        var rawRefresh = RandomTokens.newToken();
        refreshTokens.save(
                new RefreshToken(Sha256.hex(rawRefresh), familyId, account.getId(), now, now.plus(REFRESH_TTL)));
        return new Session(accessToken(account, now), ACCESS_TTL.toSeconds(), rawRefresh, account.isEmailVerified());
    }

    // email_verified is read again on every refresh, so verifying shows up in the next access token.
    private String accessToken(Account account, Instant now) {
        var profileTypes = profiles.findByAccountId(account.getId()).stream()
                .map(p -> p.getType().name())
                .toList();
        var claims = JwtClaimsSet.builder()
                .subject(account.getId().toString())
                .issuedAt(now)
                .expiresAt(now.plus(ACCESS_TTL))
                .claim("profiles", profileTypes)
                .claim(EMAIL_VERIFIED_CLAIM, account.isEmailVerified())
                .claim(PURPOSE_CLAIM, ACCESS_PURPOSE)
                .build();
        var header = JwsHeader.with(MacAlgorithm.HS256).build();
        return jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
    }

    public record Session(String accessToken, long expiresIn, String refreshToken, boolean emailVerified) {}
}
