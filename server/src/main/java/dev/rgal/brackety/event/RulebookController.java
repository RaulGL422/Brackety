package dev.rgal.brackety.event;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/events/{eventId}/rulebook")
@RequiresVerifiedEmail
class RulebookController {

    private final RulebookService rulebooks;

    RulebookController(RulebookService rulebooks) {
        this.rulebooks = rulebooks;
    }

    /** {@code fileName} null when the phase has none. */
    record RulebookInfo(String fileName, Integer sizeBytes) {

        static RulebookInfo of(RulebookRepository.Info info) {
            return new RulebookInfo(info.getFileName(), info.getSizeBytes());
        }
    }

    @GetMapping
    ResponseEntity<byte[]> pdf(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        var rulebook = rulebooks.get(eventId, CurrentAccount.id(jwt));
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.inline()
                                .filename(rulebook.getFileName(), StandardCharsets.UTF_8)
                                .build()
                                .toString())
                .body(rulebook.getContent());
    }

    @GetMapping("/info")
    RulebookInfo info(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return rulebooks
                .info(eventId, CurrentAccount.id(jwt))
                .map(RulebookInfo::of)
                .orElse(new RulebookInfo(null, null));
    }

    @PutMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    RulebookInfo upload(
            @PathVariable UUID eventId, @RequestParam("file") MultipartFile file, @AuthenticationPrincipal Jwt jwt) {
        try {
            return RulebookInfo.of(
                    rulebooks.upload(eventId, CurrentAccount.id(jwt), file.getOriginalFilename(), file.getBytes()));
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void delete(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        rulebooks.delete(eventId, CurrentAccount.id(jwt));
    }
}
