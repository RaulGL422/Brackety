package dev.rgal.brackety.legal;

import dev.rgal.brackety.legal.dto.LegalDocumentsResponse;
import dev.rgal.brackety.legal.dto.LegalTextResponse;
import java.time.Duration;
import java.util.Arrays;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.ErrorResponseException;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/legal")
class LegalController {

    private static final CacheControl CACHE =
            CacheControl.maxAge(Duration.ofMinutes(5)).cachePublic();

    private final LegalService legal;

    LegalController(LegalService legal) {
        this.legal = legal;
    }

    @GetMapping
    ResponseEntity<LegalDocumentsResponse> documents() {
        var documents = Arrays.stream(LegalDocument.values())
                .map(d -> new LegalDocumentsResponse.Document(d.slug(), d.version(), d.acceptanceRequired()))
                .toList();
        return ResponseEntity.ok()
                .cacheControl(CACHE)
                .body(new LegalDocumentsResponse(documents, legal.isPrivacyContactConfigured()));
    }

    @GetMapping("/{type}")
    ResponseEntity<LegalTextResponse> text(@PathVariable String type, @RequestParam(required = false) String lang) {
        var text = legal.text(type, lang).orElseThrow(() -> new ErrorResponseException(HttpStatus.NOT_FOUND));
        return ResponseEntity.ok().cacheControl(CACHE).body(text);
    }
}
