package dev.rgal.brackety.ranking;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import dev.rgal.brackety.ranking.dto.StandingRow;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/events/{eventId}")
@RequiresVerifiedEmail
class StandingsController {

    private static final MediaType CSV = new MediaType("text", "csv", StandardCharsets.UTF_8);

    private final StandingsService standings;

    StandingsController(StandingsService standings) {
        this.standings = standings;
    }

    @GetMapping("/standings")
    List<StandingRow> standings(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return standings.standings(eventId, CurrentAccount.id(jwt));
    }

    @GetMapping("/export/standings.csv")
    ResponseEntity<String> standingsCsv(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return csv("clasificacion.csv", standings.standingsCsv(eventId, CurrentAccount.id(jwt)));
    }

    @GetMapping("/export/matches.csv")
    ResponseEntity<String> matchesCsv(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return csv("combates.csv", standings.matchesCsv(eventId, CurrentAccount.id(jwt)));
    }

    @GetMapping("/export/timeline.csv")
    ResponseEntity<String> timelineCsv(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return csv("linea-de-tiempo.csv", standings.timelineCsv(eventId, CurrentAccount.id(jwt)));
    }

    private static ResponseEntity<String> csv(String filename, String body) {
        return ResponseEntity.ok()
                .contentType(CSV)
                .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment()
                                .filename(filename)
                                .build()
                                .toString())
                .body(body);
    }
}
