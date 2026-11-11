package dev.rgal.brackety.auth;

import dev.rgal.brackety.auth.dto.EmailRequest;
import dev.rgal.brackety.auth.dto.GoogleSignInRequest;
import dev.rgal.brackety.auth.dto.GoogleSignInResponse;
import dev.rgal.brackety.auth.dto.LoginRequest;
import dev.rgal.brackety.auth.dto.RefreshRequest;
import dev.rgal.brackety.auth.dto.RegisterRequest;
import dev.rgal.brackety.auth.dto.ResetPasswordRequest;
import dev.rgal.brackety.auth.dto.RestoreRequest;
import dev.rgal.brackety.auth.dto.TokenRequest;
import dev.rgal.brackety.auth.dto.TokenResponse;
import dev.rgal.brackety.auth.email.EmailChangeService;
import dev.rgal.brackety.auth.email.EmailVerificationService;
import dev.rgal.brackety.auth.email.PasswordResetService;
import dev.rgal.brackety.auth.google.GoogleSignInService;
import dev.rgal.brackety.auth.session.SessionService;
import dev.rgal.brackety.auth.session.SessionService.Session;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.time.Duration;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CookieValue;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(AuthController.BASE_PATH)
class AuthController {

    static final String BASE_PATH = "/api/v1/auth";
    static final String CLIENT_HEADER = "X-Client";
    static final String REFRESH_COOKIE = "brackety_refresh";

    private final AuthService auth;
    private final SessionService sessions;
    private final EmailVerificationService verification;
    private final PasswordResetService passwordReset;
    private final GoogleSignInService google;
    private final EmailChangeService emailChange;
    private final boolean secureCookie;

    AuthController(
            AuthService auth,
            SessionService sessions,
            EmailVerificationService verification,
            PasswordResetService passwordReset,
            GoogleSignInService google,
            EmailChangeService emailChange,
            @Value("${brackety.auth.refresh-cookie-secure}") boolean secureCookie) {
        this.auth = auth;
        this.sessions = sessions;
        this.verification = verification;
        this.passwordReset = passwordReset;
        this.google = google;
        this.emailChange = emailChange;
        this.secureCookie = secureCookie;
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.ACCEPTED)
    void register(@Valid @RequestBody RegisterRequest request) {
        try {
            auth.register(request);
        } catch (DataIntegrityViolationException e) {
            // A concurrent registration took the email first: answer as for any duplicate, without revealing it.
        }
    }

    @PostMapping("/login")
    ResponseEntity<TokenResponse> login(
            @Valid @RequestBody LoginRequest request,
            @RequestHeader(name = CLIENT_HEADER, required = false) String client,
            HttpServletRequest http) {
        return respond(auth.login(request.email(), request.password(), http.getRemoteAddr()), isWeb(client));
    }

    @PostMapping("/google")
    ResponseEntity<GoogleSignInResponse> google(
            @Valid @RequestBody GoogleSignInRequest request,
            @RequestHeader(name = CLIENT_HEADER, required = false) String client) {
        var result = googleSignInRetryingOnce(request);
        if (result.session() == null) {
            return ResponseEntity.ok(GoogleSignInResponse.registrationRequired(result.registrationEmail()));
        }
        var web = isWeb(client);
        return withRefreshCookie(result.session(), web)
                .body(GoogleSignInResponse.signedIn(tokens(result.session(), web), result.replacedUnverifiedAccount()));
    }

    // A concurrent sign-up with the same Google account or email committed first and this one rolled back.
    // Run again: it now finds that account and signs in (or gets its usual answer).
    private GoogleSignInService.Result googleSignInRetryingOnce(GoogleSignInRequest request) {
        try {
            return google.signIn(request.idToken(), request.registration());
        } catch (DataIntegrityViolationException first) {
            try {
                return google.signIn(request.idToken(), request.registration());
            } catch (DataIntegrityViolationException again) {
                throw AuthException.signInConflict();
            }
        }
    }

    @PostMapping("/restore")
    ResponseEntity<TokenResponse> restore(
            @Valid @RequestBody RestoreRequest request,
            @RequestHeader(name = CLIENT_HEADER, required = false) String client) {
        return respond(auth.restore(request.restoreToken()), isWeb(client));
    }

    @PostMapping("/refresh")
    ResponseEntity<TokenResponse> refresh(
            @CookieValue(name = REFRESH_COOKIE, required = false) String cookie,
            @RequestBody(required = false) RefreshRequest body,
            @RequestHeader(name = CLIENT_HEADER, required = false) String client) {
        // A token that came in the cookie goes back in the cookie, so a script can never read it from the body.
        return respond(sessions.refresh(refreshToken(cookie, body)), hasText(cookie) || isWeb(client));
    }

    @PostMapping("/logout")
    ResponseEntity<Void> logout(
            @CookieValue(name = REFRESH_COOKIE, required = false) String cookie,
            @RequestBody(required = false) RefreshRequest body) {
        sessions.logout(refreshToken(cookie, body));
        return ResponseEntity.noContent()
                .header(HttpHeaders.SET_COOKIE, refreshCookie("", Duration.ZERO))
                .build();
    }

    @PostMapping("/email/verify")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void verifyEmail(@Valid @RequestBody TokenRequest request) {
        verification.verify(request.token());
    }

    @PostMapping("/email/resend")
    @ResponseStatus(HttpStatus.ACCEPTED)
    void resendVerification(@Valid @RequestBody EmailRequest request) {
        verification.resend(request.email());
    }

    @PostMapping("/email/change/confirm")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void confirmEmailChange(@Valid @RequestBody TokenRequest request) {
        emailChange.confirm(request.token());
    }

    @PostMapping("/password/forgot")
    @ResponseStatus(HttpStatus.ACCEPTED)
    void forgotPassword(@Valid @RequestBody EmailRequest request) {
        passwordReset.forgot(request.email());
    }

    @PostMapping("/password/reset")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        passwordReset.reset(request.token(), request.newPassword());
    }

    @PostMapping("/password/reset/check")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void checkResetLink(@Valid @RequestBody TokenRequest request) {
        passwordReset.check(request.token());
    }

    private ResponseEntity<TokenResponse> respond(Session session, boolean web) {
        return withRefreshCookie(session, web).body(tokens(session, web));
    }

    // Web keeps the refresh token in an httpOnly cookie, out of reach of scripts; Android gets it in the body.
    private ResponseEntity.BodyBuilder withRefreshCookie(Session session, boolean web) {
        var response = ResponseEntity.ok();
        if (web) {
            response.header(HttpHeaders.SET_COOKIE, refreshCookie(session.refreshToken(), SessionService.REFRESH_TTL));
        }
        return response;
    }

    private static TokenResponse tokens(Session session, boolean web) {
        return new TokenResponse(
                session.accessToken(),
                session.expiresIn(),
                web ? null : session.refreshToken(),
                session.emailVerified());
    }

    private static boolean isWeb(String client) {
        return "web".equalsIgnoreCase(client);
    }

    private static boolean hasText(String value) {
        return value != null && !value.isBlank();
    }

    private static String refreshToken(String cookie, RefreshRequest body) {
        if (hasText(cookie)) {
            return cookie;
        }
        return body == null ? null : body.refreshToken();
    }

    private String refreshCookie(String value, Duration maxAge) {
        return ResponseCookie.from(REFRESH_COOKIE, value)
                .httpOnly(true)
                .secure(secureCookie)
                .sameSite("Strict")
                .path(BASE_PATH)
                .maxAge(maxAge)
                .build()
                .toString();
    }
}
