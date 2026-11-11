package dev.rgal.brackety.eventpackage;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import dev.rgal.brackety.eventpackage.EventPackageService.ResultsImport;
import java.util.UUID;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiresVerifiedEmail
class EventPackageController {

    private final EventPackageService packages;

    EventPackageController(EventPackageService packages) {
        this.packages = packages;
    }

    @GetMapping("/api/v1/events/{eventId}/export/package")
    ResponseEntity<EventPackage> export(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        var result = packages.export(eventId, CurrentAccount.id(jwt));
        var filename = EventPackageService.slug(result.event().name()) + "-"
                + result.event().date() + ".brackety";
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_JSON)
                .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment()
                                .filename(filename)
                                .build()
                                .toString())
                .body(result);
    }

    /** The body is the file as it is: the full export (.zip) or the package (.brackety). */
    @PostMapping(path = "/api/v1/events/{eventId}/import/results", consumes = MediaType.APPLICATION_OCTET_STREAM_VALUE)
    ResultsImport importResults(
            @PathVariable UUID eventId,
            @RequestParam(defaultValue = "false") boolean dryRun,
            @RequestBody byte[] file,
            @AuthenticationPrincipal Jwt jwt) {
        return packages.importResults(eventId, CurrentAccount.id(jwt), file, dryRun);
    }
}
