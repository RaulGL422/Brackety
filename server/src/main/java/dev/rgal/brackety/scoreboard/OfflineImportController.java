package dev.rgal.brackety.scoreboard;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import dev.rgal.brackety.live.LiveHub;
import dev.rgal.brackety.live.LiveTopics;
import dev.rgal.brackety.scoreboard.dto.OfflineImportResponse;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiresVerifiedEmail
class OfflineImportController {

    private final OfflineImportService imports;
    private final LiveHub hub;

    OfflineImportController(OfflineImportService imports, LiveHub hub) {
        this.imports = imports;
        this.hub = hub;
    }

    /** The CSV a device exported, as the raw body; read as UTF-8 whatever the content type says. */
    @PostMapping(
            value = "/api/v1/events/{eventId}/offline-ops/import",
            consumes = {"text/csv", "text/plain", "application/octet-stream"})
    OfflineImportResponse importCsv(
            @PathVariable UUID eventId, @RequestBody byte[] csv, @AuthenticationPrincipal Jwt jwt) {
        var outcome = imports.importCsv(eventId, CurrentAccount.id(jwt), new String(csv, StandardCharsets.UTF_8));
        // The event's watchers hear of it from LiveChangeInterceptor; each match's scoreboard, from here.
        hub.publish(outcome.changedMatches().stream().map(LiveTopics::match).toList());
        return outcome.response();
    }
}
