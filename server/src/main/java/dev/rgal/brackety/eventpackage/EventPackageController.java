package dev.rgal.brackety.eventpackage;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import java.text.Normalizer;
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
        var filename = slug(result.event().name()) + "-" + result.event().date() + ".brackety";
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

    /** "Liga Yoseikan · Fase 1" → "liga-yoseikan-fase-1". */
    static String slug(String name) {
        var slug = Normalizer.normalize(name, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9]+", "-")
                .replaceAll("^-|-$", "");
        return slug.isEmpty() ? "evento" : slug;
    }
}
