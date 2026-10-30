package dev.rgal.brackety.auth;

import java.security.SecureRandom;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
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
    static final Duration REFRESH_TTL = Duration.ofDays(30);

    private static final Logger log = LoggerFactory.getLogger(SessionService.class);

    private final RefreshTokenRepository refreshTokens;
    private final AccountRepository accounts;
    private final ProfileRepository profiles;
    private final JwtEncoder jwtEncoder;
    private final Clock clock;
    private final SecureRandom random = new SecureRandom();

    SessionService(
            RefreshTokenRepository refreshTokens,
            AccountRepository accounts,
            ProfileRepository profiles,
            JwtEncoder jwtEncoder,
            Clock clock) {
        this.refreshTokens = refreshTokens;
        this.accounts = accounts;
        this.profiles = profiles;
        this.jwtEncoder = jwtEncoder;
        this.clock = clock;
    }

    @Transactional
    Session start(UUID accountId) {
        return issue(accountId, UUID.randomUUID(), clock.instant());
    }

    // No rollback on AuthException: revoking a family on reuse must be committed even though the call fails.
    @Transactional(noRollbackFor = AuthException.class)
    public Session refresh(String rawToken) {
        var now = clock.instant();
        var token = find(rawToken);
        if (token.isRevoked()) {
            throw AuthException.invalidSession();
        }
        if (token.isUsed()) {
            refreshTokens.revokeFamily(token.getFamilyId(), now);
            log.warn("Refresh token reused: session family {} revoked", token.getFamilyId());
            // feat/auth-email: warn the account owner by email here.
            throw AuthException.invalidSession();
        }
        if (token.isExpired(now)
                || !accounts.findById(token.getAccountId())
                        .map(Account::isActive)
                        .orElse(false)) {
            throw AuthException.invalidSession();
        }
        token.markUsed(now);
        return issue(token.getAccountId(), token.getFamilyId(), now);
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

    private Session issue(UUID accountId, UUID familyId, Instant now) {
        var bytes = new byte[32];
        random.nextBytes(bytes);
        var rawRefresh = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        refreshTokens.save(new RefreshToken(Sha256.hex(rawRefresh), familyId, accountId, now, now.plus(REFRESH_TTL)));
        return new Session(accessToken(accountId, now), ACCESS_TTL.toSeconds(), rawRefresh);
    }

    private String accessToken(UUID accountId, Instant now) {
        var profileTypes = profiles.findByAccountId(accountId).stream()
                .map(p -> p.getType().name())
                .toList();
        var claims = JwtClaimsSet.builder()
                .subject(accountId.toString())
                .issuedAt(now)
                .expiresAt(now.plus(ACCESS_TTL))
                .claim("profiles", profileTypes)
                .build();
        var header = JwsHeader.with(MacAlgorithm.HS256).build();
        return jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
    }

    public record Session(String accessToken, long expiresIn, String refreshToken) {}
}
