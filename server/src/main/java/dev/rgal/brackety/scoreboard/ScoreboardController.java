package dev.rgal.brackety.scoreboard;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import dev.rgal.brackety.scoreboard.dto.MatchEventRequest;
import dev.rgal.brackety.scoreboard.dto.MatchView;
import dev.rgal.brackety.scoreboard.dto.ReviewRequest;
import dev.rgal.brackety.scoreboard.dto.ReviewResponse;
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
    private final MatchReviewService reviews;

    ScoreboardController(ScoreboardService scoreboard, MatchReviewService reviews) {
        this.scoreboard = scoreboard;
        this.reviews = reviews;
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
        // Thrown here, after the commit: a rejected offline action stays saved for the review.
        var recorded = scoreboard.record(matchId, CurrentAccount.id(jwt), request);
        if (recorded.conflictCode() != null) {
            throw ScoreboardService.offlineConflict(recorded.conflictCode());
        }
        return recorded.view();
    }

    @PostMapping("/review")
    ReviewResponse review(
            @PathVariable UUID matchId, @Valid @RequestBody ReviewRequest request, @AuthenticationPrincipal Jwt jwt) {
        return reviews.review(matchId, CurrentAccount.id(jwt), request);
    }
}
