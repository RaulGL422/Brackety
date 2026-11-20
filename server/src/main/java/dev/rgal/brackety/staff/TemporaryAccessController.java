package dev.rgal.brackety.staff;

import dev.rgal.brackety.common.CurrentAccount;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.staff.dto.TemporaryAccessResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** QR accesses of an event, for its club. Signing in with one is {@code POST /api/v1/auth/temporary}. */
@RestController
@RequestMapping("/api/v1/events/{eventId}/temporary-access")
class TemporaryAccessController {

    private final TemporaryAccessService service;

    TemporaryAccessController(TemporaryAccessService service) {
        this.service = service;
    }

    record CreateRequest(
            @NotBlank @Size(max = 120) String name,
            @NotNull EventRole role,
            @Min(1) @Max(99) Integer mat) {}

    @GetMapping
    List<TemporaryAccessResponse> list(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return service.list(eventId, CurrentAccount.id(jwt));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    TemporaryAccessResponse create(
            @PathVariable UUID eventId, @Valid @RequestBody CreateRequest request, @AuthenticationPrincipal Jwt jwt) {
        return service.create(eventId, CurrentAccount.id(jwt), request.name(), request.role(), request.mat());
    }

    @PostMapping("/{accessId}/renew")
    TemporaryAccessResponse renew(
            @PathVariable UUID eventId, @PathVariable UUID accessId, @AuthenticationPrincipal Jwt jwt) {
        return service.renew(eventId, CurrentAccount.id(jwt), accessId);
    }

    @PostMapping("/{accessId}/end")
    TemporaryAccessResponse end(
            @PathVariable UUID eventId, @PathVariable UUID accessId, @AuthenticationPrincipal Jwt jwt) {
        return service.end(eventId, CurrentAccount.id(jwt), accessId);
    }
}
