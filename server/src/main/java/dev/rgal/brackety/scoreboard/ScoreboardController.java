package dev.rgal.brackety.scoreboard;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import dev.rgal.brackety.scoreboard.dto.MatchEventRequest;
import dev.rgal.brackety.scoreboard.dto.MatchView;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/matches/{matchId}")
@RequiresVerifiedEmail
class ScoreboardController {

    private final ScoreboardService scoreboard;

    ScoreboardController(ScoreboardService scoreboard) {
        this.scoreboard = scoreboard;
    }

    @GetMapping
    MatchView view(@PathVariable UUID matchId, @AuthenticationPrincipal Jwt jwt) {
        return scoreboard.view(matchId, CurrentAccount.id(jwt));
    }

    @PostMapping("/events")
    MatchView record(
            @PathVariable UUID matchId,
            @Valid @RequestBody MatchEventRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        return scoreboard.record(matchId, CurrentAccount.id(jwt), request);
    }
}
