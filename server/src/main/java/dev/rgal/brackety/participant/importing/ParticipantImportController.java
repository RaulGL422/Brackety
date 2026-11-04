package dev.rgal.brackety.participant.importing;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import dev.rgal.brackety.participant.importing.dto.CheckedRow;
import dev.rgal.brackety.participant.importing.dto.ImportRequest;
import dev.rgal.brackety.participant.importing.dto.ImportResult;
import jakarta.validation.Valid;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
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
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/events/{eventId}/participants/import")
@RequiresVerifiedEmail
class ParticipantImportController {

    private static final Map<String, String> TYPES_BY_EXTENSION = Map.of(
            "csv", "text/plain",
            "txt", "text/plain",
            "xlsx", ParticipantImportService.XLSX,
            "jpg", "image/jpeg",
            "jpeg", "image/jpeg",
            "png", "image/png",
            "webp", "image/webp");

    private final ParticipantImportService imports;

    ParticipantImportController(ParticipantImportService imports) {
        this.imports = imports;
    }

    @GetMapping("/available")
    Map<String, Boolean> available(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return Map.of("available", imports.isAvailable(eventId, CurrentAccount.id(jwt)));
    }

    /** Photos or files of a list, or pasted text; answers the rows checked, keeps nothing. */
    @PostMapping(value = "/read", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    List<CheckedRow> read(
            @PathVariable UUID eventId,
            @RequestParam(name = "files", required = false) List<MultipartFile> files,
            @RequestParam(name = "text", required = false) String text,
            @RequestParam(name = "consentVersion", required = false) String consentVersion,
            @AuthenticationPrincipal Jwt jwt) {
        var list = new ArrayList<ListFile>();
        if (files != null) {
            files.forEach(f -> list.add(listFile(f)));
        }
        if (text != null && !text.isBlank()) {
            list.add(new ListFile("text/plain", text.getBytes(StandardCharsets.UTF_8)));
        }
        return imports.read(eventId, CurrentAccount.id(jwt), list, consentVersion);
    }

    /** Checks the rows again after the club edits them; no Claude involved. */
    @PostMapping("/check")
    List<CheckedRow> check(
            @PathVariable UUID eventId, @Valid @RequestBody ImportRequest request, @AuthenticationPrincipal Jwt jwt) {
        return imports.check(eventId, CurrentAccount.id(jwt), request.rows());
    }

    /** 201 with every participant registered, or 422 with the rows that stop it and nothing saved. */
    @PostMapping
    ResponseEntity<ImportResult> register(
            @PathVariable UUID eventId, @Valid @RequestBody ImportRequest request, @AuthenticationPrincipal Jwt jwt) {
        var result = imports.register(eventId, CurrentAccount.id(jwt), request);
        var status = result.registered() > 0 ? HttpStatus.CREATED : HttpStatus.UNPROCESSABLE_CONTENT;
        return ResponseEntity.status(status).body(result);
    }

    // By the extension first: browsers disagree on the type of a CSV (Windows says Excel).
    private static ListFile listFile(MultipartFile file) {
        var name = file.getOriginalFilename() == null ? "" : file.getOriginalFilename();
        var dot = name.lastIndexOf('.');
        var extension = dot < 0 ? "" : name.substring(dot + 1).toLowerCase(Locale.ROOT);
        var type =
                TYPES_BY_EXTENSION.getOrDefault(extension, file.getContentType() == null ? "" : file.getContentType());
        try {
            return new ListFile(type, file.getBytes());
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
