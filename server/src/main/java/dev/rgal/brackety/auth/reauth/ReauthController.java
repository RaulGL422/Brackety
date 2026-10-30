package dev.rgal.brackety.auth.reauth;

import dev.rgal.brackety.auth.dto.ReauthRequest;
import dev.rgal.brackety.auth.dto.ReauthResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
class ReauthController {

    private final ReauthService reauth;

    ReauthController(ReauthService reauth) {
        this.reauth = reauth;
    }

    @PostMapping("/api/v1/me/reauth")
    ReauthResponse reauthenticate(
            @AuthenticationPrincipal Jwt jwt, @Valid @RequestBody ReauthRequest request, HttpServletRequest http) {
        return reauth.reauthenticate(UUID.fromString(jwt.getSubject()), request, http.getRemoteAddr());
    }
}
