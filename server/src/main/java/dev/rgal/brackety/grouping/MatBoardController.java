package dev.rgal.brackety.grouping;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import dev.rgal.brackety.grouping.dto.MatBoardResponse;
import dev.rgal.brackety.grouping.dto.MatOverview;
import java.util.List;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1")
@RequiresVerifiedEmail
class MatBoardController {

    private final MatBoardService boards;

    MatBoardController(MatBoardService boards) {
        this.boards = boards;
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
