package dev.rgal.brackety.grouping;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import dev.rgal.brackety.grouping.dto.ControlRequests.MoveRequest;
import dev.rgal.brackety.grouping.dto.ControlRequests.OrderRequest;
import dev.rgal.brackety.grouping.dto.ControlRequests.TeamMoveRequest;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** The club's control panel (MatchControlService); the superadmin has the same under /api/v1/admin. */
@RestController
@RequestMapping("/api/v1/events/{eventId}/control")
@RequiresVerifiedEmail
class MatchControlController {

    private final MatchControlService control;

    MatchControlController(MatchControlService control) {
        this.control = control;
    }

    @PutMapping("/groups/{groupId}/mat")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void moveGroup(
            @PathVariable UUID eventId,
            @PathVariable UUID groupId,
            @Valid @RequestBody MoveRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        var by = club(eventId, jwt);
        control.moveGroup(eventId, groupId, request.matId(), by);
    }

    @PutMapping("/matches/{matchId}/mat")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void moveMatch(
            @PathVariable UUID eventId,
            @PathVariable UUID matchId,
            @Valid @RequestBody MoveRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        var by = club(eventId, jwt);
        control.moveMatch(eventId, matchId, request.matId(), by);
    }

    @PutMapping("/groups/{groupId}/order")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void reorder(
            @PathVariable UUID eventId,
            @PathVariable UUID groupId,
            @Valid @RequestBody OrderRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        var by = club(eventId, jwt);
        control.reorder(eventId, groupId, request.matchIds(), by);
    }

    @PostMapping("/team-members")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void moveTeamMember(
            @PathVariable UUID eventId, @Valid @RequestBody TeamMoveRequest request, @AuthenticationPrincipal Jwt jwt) {
        var by = club(eventId, jwt);
        control.moveTeamMember(eventId, request.participantId(), request.fromTeamId(), request.toTeamId(), by);
    }

    @PostMapping("/matches/{matchId}/waive-rest")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void waiveRest(@PathVariable UUID eventId, @PathVariable UUID matchId, @AuthenticationPrincipal Jwt jwt) {
        var by = club(eventId, jwt);
        control.waiveRest(eventId, matchId, by);
    }

    private UUID club(UUID eventId, Jwt jwt) {
        var account = CurrentAccount.id(jwt);
        control.requireClub(eventId, account);
        return account;
    }
}
