package dev.rgal.brackety.participant;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import dev.rgal.brackety.participant.dto.ParticipantRequest;
import dev.rgal.brackety.participant.dto.ParticipantResponse;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/events/{eventId}/participants")
@RequiresVerifiedEmail
class ParticipantController {

    private final ParticipantService participants;

    ParticipantController(ParticipantService participants) {
        this.participants = participants;
    }

    @GetMapping
    List<ParticipantResponse> list(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return participants.list(eventId, CurrentAccount.id(jwt));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    ParticipantResponse create(
            @PathVariable UUID eventId,
            @Valid @RequestBody ParticipantRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        return participants.create(eventId, CurrentAccount.id(jwt), request);
    }

    @PutMapping("/{participantId}")
    ParticipantResponse update(
            @PathVariable UUID eventId,
            @PathVariable UUID participantId,
            @Valid @RequestBody ParticipantRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        return participants.update(eventId, participantId, CurrentAccount.id(jwt), request);
    }

    @DeleteMapping("/{participantId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void delete(@PathVariable UUID eventId, @PathVariable UUID participantId, @AuthenticationPrincipal Jwt jwt) {
        participants.delete(eventId, participantId, CurrentAccount.id(jwt));
    }
}
