package dev.rgal.brackety.staff;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.staff.dto.InvitationResponse;
import dev.rgal.brackety.staff.dto.InvitationView;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Invitations of helpers and referees (F1-5). The token goes in the body, never in a URL the logs keep. */
@RestController
class StaffController {

    private final StaffService service;

    StaffController(StaffService service) {
        this.service = service;
    }

    record InviteRequest(
            @NotBlank @Email @Size(max = 254) String email,
            @NotNull EventRole role) {}

    record TokenRequest(@NotBlank @Size(max = 100) String token) {}

    record Accepted(UUID eventId) {}

    @GetMapping("/api/v1/events/{eventId}/invitations")
    List<InvitationResponse> pending(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return service.pending(eventId, CurrentAccount.id(jwt));
    }

    @PostMapping("/api/v1/events/{eventId}/invitations")
    @ResponseStatus(HttpStatus.CREATED)
    InvitationResponse invite(
            @PathVariable UUID eventId, @Valid @RequestBody InviteRequest request, @AuthenticationPrincipal Jwt jwt) {
        return service.invite(eventId, CurrentAccount.id(jwt), request.email(), request.role());
    }

    @DeleteMapping("/api/v1/events/{eventId}/invitations/{invitationId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void cancel(@PathVariable UUID eventId, @PathVariable UUID invitationId, @AuthenticationPrincipal Jwt jwt) {
        service.cancel(eventId, CurrentAccount.id(jwt), invitationId);
    }

    @DeleteMapping("/api/v1/events/{eventId}/staff/{accountId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void remove(
            @PathVariable UUID eventId,
            @PathVariable UUID accountId,
            @RequestParam EventRole role,
            @AuthenticationPrincipal Jwt jwt) {
        service.remove(eventId, CurrentAccount.id(jwt), accountId, role);
    }

    @PostMapping("/api/v1/invitations/view")
    InvitationView view(@Valid @RequestBody TokenRequest request, @AuthenticationPrincipal Jwt jwt) {
        return service.view(request.token(), CurrentAccount.id(jwt));
    }

    @PostMapping("/api/v1/invitations/accept")
    @RequiresVerifiedEmail
    Accepted accept(@Valid @RequestBody TokenRequest request, @AuthenticationPrincipal Jwt jwt) {
        return new Accepted(service.accept(request.token(), CurrentAccount.id(jwt)));
    }
}
