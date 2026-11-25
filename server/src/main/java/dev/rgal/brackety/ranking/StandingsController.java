package dev.rgal.brackety.ranking;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import dev.rgal.brackety.ranking.dto.LeagueRecord;
import dev.rgal.brackety.ranking.dto.LeagueStandings;
import dev.rgal.brackety.ranking.dto.ParticipantRecord;
import dev.rgal.brackety.ranking.dto.StandingRow;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
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
    private static final MediaType PDF = MediaType.APPLICATION_PDF;

    private final StandingsService standings;
    private final LeagueStandingsService leagueStandings;
    private final Exports exports;
    private final FullExportService fullExport;
    private final ParticipantRecordService records;
    private final DownloadNames names;

    StandingsController(
            StandingsService standings,
            LeagueStandingsService leagueStandings,
            Exports exports,
            FullExportService fullExport,
            ParticipantRecordService records,
            DownloadNames names) {
        this.records = records;
        this.names = names;
        this.standings = standings;
        this.leagueStandings = leagueStandings;
        this.exports = exports;
        this.fullExport = fullExport;
    }

    /** One participant's standing and matches, for the club. */
    @GetMapping("/participants/{participantId}/record")
    ParticipantRecord record(
            @PathVariable UUID eventId, @PathVariable UUID participantId, @AuthenticationPrincipal Jwt jwt) {
        return records.record(eventId, participantId, CurrentAccount.id(jwt));
    }

    /** One person's matches in every phase of the league, for the club (warnings and their reasons). */
    @GetMapping("/league/people/{personId}/record")
    LeagueRecord leagueRecord(
            @PathVariable UUID eventId, @PathVariable UUID personId, @AuthenticationPrincipal Jwt jwt) {
        return records.leagueRecord(eventId, personId, CurrentAccount.id(jwt));
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
        return file(
                eventId,
                "clasificacion-fase.csv",
                CSV,
                exports.builtIn(eventId, CurrentAccount.id(jwt), "standings").csv());
    }

    @GetMapping("/export/league-standings.csv")
    ResponseEntity<byte[]> leagueStandingsCsv(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return file(
                eventId,
                "clasificacion-liga.csv",
                CSV,
                exports.builtIn(eventId, CurrentAccount.id(jwt), "league").csv());
    }

    /** One CSV of the league standings per category, in a .zip. */
    @GetMapping("/export/league-standings-by-category.zip")
    ResponseEntity<byte[]> categoryStandings(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        var files = new LinkedHashMap<String, byte[]>();
        exports.leagueByCategory(eventId, CurrentAccount.id(jwt))
                .forEach((name, csv) -> files.put(names.of(eventId, name), Zip.text(csv)));
        return file(eventId, "clasificacion-por-categoria.zip", ZIP, Zip.of(files));
    }

    @GetMapping("/export/league-standings.pdf")
    ResponseEntity<byte[]> standingsPdf(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return file(
                eventId, "clasificacion-por-categoria.pdf", PDF, leagueStandings.pdf(eventId, CurrentAccount.id(jwt)));
    }

    @GetMapping("/export/matches.csv")
    ResponseEntity<byte[]> matchesCsv(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return file(
                eventId,
                "combates.csv",
                CSV,
                exports.builtIn(eventId, CurrentAccount.id(jwt), "matches").csv());
    }

    @GetMapping("/export/timeline.csv")
    ResponseEntity<byte[]> timelineCsv(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return file(
                eventId,
                "linea-de-tiempo.csv",
                CSV,
                exports.builtIn(eventId, CurrentAccount.id(jwt), "timeline").csv());
    }

    @GetMapping("/export/participants.csv")
    ResponseEntity<byte[]> participantsCsv(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return file(
                eventId,
                "participantes.csv",
                CSV,
                exports.builtIn(eventId, CurrentAccount.id(jwt), "participants").csv());
    }

    /** Every sheet, the event package and a LEEME.txt in one .zip. */
    @GetMapping("/export/full")
    ResponseEntity<byte[]> full(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        var export = fullExport.export(eventId, CurrentAccount.id(jwt));
        return attachment(export.filename(), ZIP, export.zip());
    }

    // The body comes first: it checks the account may download it before the name reads the event.
    private ResponseEntity<byte[]> file(UUID eventId, String what, MediaType type, String body) {
        return file(eventId, what, type, body.getBytes(StandardCharsets.UTF_8));
    }

    private ResponseEntity<byte[]> file(UUID eventId, String what, MediaType type, byte[] body) {
        return attachment(names.of(eventId, what), type, body);
    }

    private static ResponseEntity<byte[]> attachment(String filename, MediaType type, byte[] body) {
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
