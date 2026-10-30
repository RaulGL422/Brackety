package dev.rgal.brackety.auth.identity;

import dev.rgal.brackety.auth.dto.IdTokenRequest;
import dev.rgal.brackety.auth.dto.SignInMethodResponse;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

// A handful of sign-in methods per account at most: no pagination.
@RestController
@RequestMapping("/api/v1/me")
class IdentityController {

    private final IdentityService identities;

    IdentityController(IdentityService identities) {
        this.identities = identities;
    }

    @GetMapping("/identities")
    List<SignInMethodResponse> methods(@AuthenticationPrincipal Jwt jwt) {
        return identities.methods(accountId(jwt));
    }

    @PostMapping("/identities/google")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void linkGoogle(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody IdTokenRequest request) {
        identities.linkGoogle(accountId(jwt), request.idToken());
    }

    @DeleteMapping("/identities/google")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void unlinkGoogle(@AuthenticationPrincipal Jwt jwt) {
        identities.unlinkGoogle(accountId(jwt));
    }

    @DeleteMapping("/password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void removePassword(@AuthenticationPrincipal Jwt jwt) {
        identities.removePassword(accountId(jwt));
    }

    private static UUID accountId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
