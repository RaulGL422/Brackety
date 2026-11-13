package dev.rgal.brackety.grouping;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import dev.rgal.brackety.grouping.dto.ControlRequests;
import dev.rgal.brackety.grouping.dto.MatBoardResponse;
import dev.rgal.brackety.grouping.dto.MatOverview;
import jakarta.validation.Valid;
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

@RestController
@RequestMapping("/api/v1")
@RequiresVerifiedEmail
class MatBoardController {

    private final MatBoardService boards;
    private final MatchControlService control;

    MatBoardController(MatBoardService boards, MatchControlService control) {
        this.boards = boards;
        this.control = control;
    }

    /** The referee sends one of their mat's pending matches to another mat (MatchControlService). */
    @PostMapping("/matches/{matchId}/move")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void move(
            @PathVariable UUID matchId,
            @Valid @RequestBody ControlRequests.MoveRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        control.moveMatchAsReferee(matchId, request.matId(), CurrentAccount.id(jwt));
    }

    @GetMapping("/events/{eventId}/mats")
    List<MatOverview> overview(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return boards.overview(eventId, CurrentAccount.id(jwt));
    }

    @GetMapping("/mats/{matId}/board")
    MatBoardResponse board(@PathVariable UUID matId, @AuthenticationPrincipal Jwt jwt) {
        return boards.board(matId, CurrentAccount.id(jwt));
    }
}
