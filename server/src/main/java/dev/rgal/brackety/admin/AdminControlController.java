package dev.rgal.brackety.admin;

import dev.rgal.brackety.auth.admin.AdminAuditLog;
import dev.rgal.brackety.grouping.MatchControlService;
import dev.rgal.brackety.grouping.dto.ControlRequests.DisableMatRequest;
import dev.rgal.brackety.grouping.dto.ControlRequests.MoveRequest;
import dev.rgal.brackety.grouping.dto.ControlRequests.OrderRequest;
import dev.rgal.brackety.grouping.dto.ControlRequests.TeamMoveRequest;
import dev.rgal.brackety.grouping.dto.DisabledMat;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** The superadmin's control panel: the club's (MatchControlService), on any event, under the superadmin's access. */
@RestController
@RequestMapping("/api/v1/admin/events/{eventId}/control")
class AdminControlController {

    private final MatchControlService control;
    private final AdminAuditLog audit;

    AdminControlController(MatchControlService control, AdminAuditLog audit) {
        this.control = control;
        this.audit = audit;
    }

    @PutMapping("/groups/{groupId}/mat")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void moveGroup(@PathVariable UUID eventId, @PathVariable UUID groupId, @Valid @RequestBody MoveRequest request) {
        control.moveGroup(eventId, groupId, request.matId(), null);
        audit.control(groupId, "group moved to mat " + request.matId());
    }

    @PutMapping("/matches/{matchId}/mat")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void moveMatch(@PathVariable UUID eventId, @PathVariable UUID matchId, @Valid @RequestBody MoveRequest request) {
        control.moveMatch(eventId, matchId, request.matId(), null);
        audit.control(matchId, "match moved to mat " + request.matId());
    }

    @PutMapping("/groups/{groupId}/order")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void reorder(@PathVariable UUID eventId, @PathVariable UUID groupId, @Valid @RequestBody OrderRequest request) {
        control.reorder(eventId, groupId, request.matchIds(), null);
        audit.control(groupId, "pending matches reordered");
    }

    @PostMapping("/team-members")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void moveTeamMember(@PathVariable UUID eventId, @Valid @RequestBody TeamMoveRequest request) {
        control.moveTeamMember(eventId, request.participantId(), request.fromTeamId(), request.toTeamId(), null);
        audit.control(request.participantId(), "moved from team " + request.fromTeamId() + " to " + request.toTeamId());
    }

    @PostMapping("/mats/{matId}/disable")
    DisabledMat disableMat(
            @PathVariable UUID eventId,
            @PathVariable UUID matId,
            @Valid @RequestBody(required = false) DisableMatRequest request) {
        var disabled = control.disableMat(eventId, matId, DisableMatRequest.chosen(request), null);
        audit.control(matId, "mat out of use");
        return disabled;
    }

    @PostMapping("/matches/{matchId}/waive-rest")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void waiveRest(@PathVariable UUID eventId, @PathVariable UUID matchId) {
        control.waiveRest(eventId, matchId, null);
        audit.control(matchId, "may start without the least rest");
    }
}
