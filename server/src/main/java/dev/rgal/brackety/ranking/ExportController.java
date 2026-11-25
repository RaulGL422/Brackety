package dev.rgal.brackety.ranking;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import dev.rgal.brackety.ranking.dto.ExportPreview;
import dev.rgal.brackety.ranking.dto.ExportRequest;
import dev.rgal.brackety.ranking.dto.ExportSheet;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Locale;
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
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Custom exports (docs/producto/exportaciones.md): the sheets and fields to choose from, a preview and the file. */
@RestController
@RequestMapping("/api/v1/events/{eventId}/exports")
@RequiresVerifiedEmail
class ExportController {

    private final Exports exports;

    ExportController(Exports exports) {
        this.exports = exports;
    }

    @GetMapping("/sheets")
    List<ExportSheet> sheets(
            @PathVariable UUID eventId,
            // Anything but "en" gives the Spanish titles.
            @RequestParam(defaultValue = "es") String locale,
            @AuthenticationPrincipal Jwt jwt) {
        return exports.sheets(eventId, CurrentAccount.id(jwt), Locale.forLanguageTag(locale));
    }

    @PostMapping("/preview")
    ExportPreview preview(
            @PathVariable UUID eventId, @Valid @RequestBody ExportRequest request, @AuthenticationPrincipal Jwt jwt) {
        return exports.preview(eventId, CurrentAccount.id(jwt), request);
    }

    @PostMapping
    ResponseEntity<byte[]> export(
            @PathVariable UUID eventId, @Valid @RequestBody ExportRequest request, @AuthenticationPrincipal Jwt jwt) {
        var download = exports.export(eventId, CurrentAccount.id(jwt), request);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(download.contentType()))
                .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment()
                                .filename(download.fileName())
                                .build()
                                .toString())
                .body(download.body());
    }
}
