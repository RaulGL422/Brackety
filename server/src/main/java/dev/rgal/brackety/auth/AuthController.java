package dev.rgal.brackety.auth;

import dev.rgal.brackety.auth.SessionService.Session;
import dev.rgal.brackety.auth.dto.LoginRequest;
import dev.rgal.brackety.auth.dto.RefreshRequest;
import dev.rgal.brackety.auth.dto.RegisterRequest;
import dev.rgal.brackety.auth.dto.TokenResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.time.Duration;
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

    AuthController(AuthService auth, SessionService sessions) {
        this.auth = auth;
        this.sessions = sessions;
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.ACCEPTED)
    void register(@Valid @RequestBody RegisterRequest request) {
        auth.register(request);
    }

    @PostMapping("/login")
    ResponseEntity<TokenResponse> login(
            @Valid @RequestBody LoginRequest request,
            @RequestHeader(name = CLIENT_HEADER, required = false) String client,
            HttpServletRequest http) {
        return respond(auth.login(request.email(), request.password(), http.getRemoteAddr()), client);
    }

    @PostMapping("/refresh")
    ResponseEntity<TokenResponse> refresh(
            @CookieValue(name = REFRESH_COOKIE, required = false) String cookie,
            @RequestBody(required = false) RefreshRequest body,
            @RequestHeader(name = CLIENT_HEADER, required = false) String client) {
        return respond(sessions.refresh(refreshToken(cookie, body)), client);
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

    // Web keeps the refresh token in an httpOnly cookie, out of reach of scripts; Android gets it in the body.
    private static ResponseEntity<TokenResponse> respond(Session session, String client) {
        if ("web".equalsIgnoreCase(client)) {
            return ResponseEntity.ok()
                    .header(HttpHeaders.SET_COOKIE, refreshCookie(session.refreshToken(), SessionService.REFRESH_TTL))
                    .body(new TokenResponse(session.accessToken(), session.expiresIn(), null));
        }
        return ResponseEntity.ok(new TokenResponse(session.accessToken(), session.expiresIn(), session.refreshToken()));
    }

    private static String refreshToken(String cookie, RefreshRequest body) {
        if (cookie != null && !cookie.isBlank()) {
            return cookie;
        }
        return body == null ? null : body.refreshToken();
    }

    private static String refreshCookie(String value, Duration maxAge) {
        return ResponseCookie.from(REFRESH_COOKIE, value)
                .httpOnly(true)
                .secure(true)
                .sameSite("Strict")
                .path(BASE_PATH)
                .maxAge(maxAge)
                .build()
                .toString();
    }
}
