package dev.rgal.brackety.league;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import dev.rgal.brackety.event.Discipline;
import dev.rgal.brackety.league.dto.LeagueDtos.DisciplineResponse;
import dev.rgal.brackety.league.dto.LeagueDtos.NewEventRequest;
import dev.rgal.brackety.league.dto.LeagueDtos.PhaseResponse;
import jakarta.validation.Valid;
import java.util.Arrays;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Creating a standalone event, by any signed-in account, which becomes its club. */
@RestController
@RequestMapping("/api/v1/events")
@RequiresVerifiedEmail
class NewEventController {

    private final NewEventService newEvents;

    NewEventController(NewEventService newEvents) {
        this.newEvents = newEvents;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    PhaseResponse create(@Valid @RequestBody NewEventRequest request, @AuthenticationPrincipal Jwt jwt) {
        return newEvents.create(CurrentAccount.id(jwt), request);
    }

    /** The sports to pick from, and which have a scoreboard today. */
    @GetMapping("/disciplines")
    List<DisciplineResponse> disciplines() {
        return Arrays.stream(Discipline.values())
                .map(d -> new DisciplineResponse(d, d.isAvailable()))
                .toList();
    }
}
