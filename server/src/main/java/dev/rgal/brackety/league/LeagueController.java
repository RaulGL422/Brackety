package dev.rgal.brackety.league;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import dev.rgal.brackety.league.dto.LeagueDtos.Candidate;
import dev.rgal.brackety.league.dto.LeagueDtos.LeagueRequest;
import dev.rgal.brackety.league.dto.LeagueDtos.LeagueResponse;
import dev.rgal.brackety.league.dto.LeagueDtos.NewPhaseRequest;
import dev.rgal.brackety.league.dto.LeagueDtos.PhaseResponse;
import dev.rgal.brackety.league.dto.LeagueDtos.ReenrolRequest;
import dev.rgal.brackety.league.dto.LeagueDtos.ReenrolResponse;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/events/{eventId}/league")
@RequiresVerifiedEmail
class LeagueController {

    private final LeagueService leagues;

    LeagueController(LeagueService leagues) {
        this.leagues = leagues;
    }

    @GetMapping
    LeagueResponse league(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return leagues.league(eventId, CurrentAccount.id(jwt));
    }

    @PutMapping
    LeagueResponse update(
            @PathVariable UUID eventId, @Valid @RequestBody LeagueRequest request, @AuthenticationPrincipal Jwt jwt) {
        return leagues.update(eventId, CurrentAccount.id(jwt), request);
    }

    @PostMapping("/phases")
    @ResponseStatus(HttpStatus.CREATED)
    PhaseResponse createPhase(
            @PathVariable UUID eventId, @Valid @RequestBody NewPhaseRequest request, @AuthenticationPrincipal Jwt jwt) {
        return leagues.createPhase(eventId, CurrentAccount.id(jwt), request);
    }

    @GetMapping("/candidates")
    List<Candidate> candidates(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return leagues.candidates(eventId, CurrentAccount.id(jwt));
    }

    @PostMapping("/reenrol")
    ReenrolResponse reenrol(
            @PathVariable UUID eventId, @Valid @RequestBody ReenrolRequest request, @AuthenticationPrincipal Jwt jwt) {
        return leagues.reenrol(eventId, CurrentAccount.id(jwt), request);
    }
}
