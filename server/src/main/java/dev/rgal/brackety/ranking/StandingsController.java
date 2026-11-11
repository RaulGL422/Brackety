package dev.rgal.brackety.ranking;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import dev.rgal.brackety.ranking.dto.LeagueStandings;
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
    private static final MediaType ZIP = new MediaType("application", "zip");

    private final StandingsService standings;
    private final LeagueStandingsService leagueStandings;
    private final EventSheets sheets;
    private final FullExportService fullExport;

    StandingsController(
            StandingsService standings,
            LeagueStandingsService leagueStandings,
            EventSheets sheets,
            FullExportService fullExport) {
        this.standings = standings;
        this.leagueStandings = leagueStandings;
        this.sheets = sheets;
        this.fullExport = fullExport;
    }

    @GetMapping("/standings")
    List<StandingRow> standings(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return standings.standings(eventId, CurrentAccount.id(jwt));
    }

    @GetMapping("/league/standings")
    LeagueStandings leagueStandings(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return leagueStandings.standings(eventId, CurrentAccount.id(jwt));
    }

    @GetMapping("/export/standings.csv")
    ResponseEntity<byte[]> standingsCsv(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return file("clasificacion-fase.csv", CSV, standings.standingsCsv(eventId, CurrentAccount.id(jwt)));
    }

    @GetMapping("/export/league-standings.csv")
    ResponseEntity<byte[]> leagueStandingsCsv(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return file("clasificacion-liga.csv", CSV, leagueStandings.csv(eventId, CurrentAccount.id(jwt)));
    }

    @GetMapping("/export/matches.csv")
    ResponseEntity<byte[]> matchesCsv(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return file("combates.csv", CSV, sheets.matchesCsv(eventId, CurrentAccount.id(jwt)));
    }

    @GetMapping("/export/timeline.csv")
    ResponseEntity<byte[]> timelineCsv(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return file("linea-de-tiempo.csv", CSV, sheets.timelineCsv(eventId, CurrentAccount.id(jwt)));
    }

    @GetMapping("/export/participants.csv")
    ResponseEntity<byte[]> participantsCsv(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return file("participantes.csv", CSV, sheets.participantsCsv(eventId, CurrentAccount.id(jwt)));
    }

    /** Every sheet, the event package and a LEEME.txt in one .zip. */
    @GetMapping("/export/full")
    ResponseEntity<byte[]> full(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        var export = fullExport.export(eventId, CurrentAccount.id(jwt));
        return file(export.filename(), ZIP, export.zip());
    }

    private static ResponseEntity<byte[]> file(String filename, MediaType type, String body) {
        return file(filename, type, body.getBytes(StandardCharsets.UTF_8));
    }

    private static ResponseEntity<byte[]> file(String filename, MediaType type, byte[] body) {
        return ResponseEntity.ok()
                .contentType(type)
                .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment()
                                .filename(filename)
                                .build()
                                .toString())
                .body(body);
    }
}
