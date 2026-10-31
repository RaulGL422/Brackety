package dev.rgal.brackety.auth.admin;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.session.SessionService;
import dev.rgal.brackety.common.crypto.Sha256;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** The single superadmin of the environment, defined by SUPERADMIN_EMAIL and SUPERADMIN_PASSWORD_HASH. */
@Service
public class AdminAuthService {

    // Purpose claim of the superadmin token: the user API rejects it, and the superadmin API accepts only it.
    public static final String ADMIN_PURPOSE = "ADMIN";
    public static final String SUBJECT = "superadmin";
    static final Duration TOKEN_TTL = Duration.ofHours(1);

    private final AuthService auth;
    private final AdminAuditRepository audit;
    private final JwtEncoder jwtEncoder;
    private final PasswordEncoder passwordEncoder;
    private final Clock clock;
    private final String emailHash;
    private final String passwordHash;

    AdminAuthService(
            AuthService auth,
            AdminAuditRepository audit,
            JwtEncoder jwtEncoder,
            PasswordEncoder passwordEncoder,
            Clock clock,
            @Value("${brackety.superadmin.email:}") String email,
            @Value("${brackety.superadmin.password-hash:}") String passwordHash) {
        this.auth = auth;
        this.audit = audit;
        this.jwtEncoder = jwtEncoder;
        this.passwordEncoder = passwordEncoder;
        this.clock = clock;
        this.emailHash = email.isBlank() ? null : Sha256.hex(Account.normalizeEmail(email));
        this.passwordHash = passwordHash.isBlank() ? null : passwordHash.strip();
    }

    // No rollback on AuthException: the lockout counters must be saved even though the login fails.
    @Transactional(noRollbackFor = AuthException.class)
    public AdminToken login(String email, String password, String clientIp) {
        if (emailHash == null || passwordHash == null) {
            throw AuthException.superadminNotConfigured();
        }
        if (!auth.checkSuperadminUnderLockout(clientIp, () -> matches(email, password))) {
            throw AuthException.invalidCredentials();
        }
        var now = clock.instant();
        audit.save(new AdminAudit(AdminAudit.Action.ADMIN_LOGIN, null, now));
        return new AdminToken(token(now), TOKEN_TTL.toSeconds());
    }

    // The hash is always checked and the emails compared in constant time, so neither the answer nor its
    // timing tells whether the email was the superadmin one.
    private boolean matches(String email, String password) {
        var passwordMatches = passwordEncoder.matches(password, passwordHash);
        var emailMatches = MessageDigest.isEqual(
                Sha256.hex(Account.normalizeEmail(email)).getBytes(StandardCharsets.US_ASCII),
                emailHash.getBytes(StandardCharsets.US_ASCII));
        return passwordMatches && emailMatches;
    }

    private String token(Instant now) {
        var claims = JwtClaimsSet.builder()
                .subject(SUBJECT)
                .issuedAt(now)
                .expiresAt(now.plus(TOKEN_TTL))
                .claim(SessionService.PURPOSE_CLAIM, ADMIN_PURPOSE)
                .build();
        var header = JwsHeader.with(MacAlgorithm.HS256).build();
        return jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
    }

    public record AdminToken(String accessToken, long expiresIn) {}
}
