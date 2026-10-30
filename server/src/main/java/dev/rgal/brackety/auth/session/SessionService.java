package dev.rgal.brackety.auth.session;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.AuthEmails;
import dev.rgal.brackety.auth.account.ProfileRepository;
import dev.rgal.brackety.common.crypto.RandomTokens;
import dev.rgal.brackety.common.crypto.Sha256;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
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
    // Two tabs or two app calls refreshing at once are not a theft: the late one gets 401 and retries.
    static final Duration REUSE_GRACE = Duration.ofSeconds(10);
    public static final String EMAIL_VERIFIED_CLAIM = "email_verified";

    private static final Logger log = LoggerFactory.getLogger(SessionService.class);

    private final RefreshTokenRepository refreshTokens;
    private final AccountRepository accounts;
    private final ProfileRepository profiles;
    private final AuthEmails authEmails;
    private final JwtEncoder jwtEncoder;
    private final Clock clock;

    SessionService(
            RefreshTokenRepository refreshTokens,
            AccountRepository accounts,
            ProfileRepository profiles,
            AuthEmails authEmails,
            JwtEncoder jwtEncoder,
            Clock clock) {
        this.refreshTokens = refreshTokens;
        this.accounts = accounts;
        this.profiles = profiles;
        this.authEmails = authEmails;
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
            throw AuthException.invalidSession();
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
        return issue(account.get(), token.getFamilyId(), now);
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
                .build();
        var header = JwsHeader.with(MacAlgorithm.HS256).build();
        return jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
    }

    public record Session(String accessToken, long expiresIn, String refreshToken, boolean emailVerified) {}
}
