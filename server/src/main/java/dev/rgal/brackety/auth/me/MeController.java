package dev.rgal.brackety.auth.me;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.auth.account.ProfileType;
import dev.rgal.brackety.auth.dto.DataExport;
import dev.rgal.brackety.auth.dto.DeletionResponse;
import dev.rgal.brackety.auth.dto.MeResponse;
import dev.rgal.brackety.auth.dto.NewEmailRequest;
import dev.rgal.brackety.auth.dto.ProfileRequest;
import dev.rgal.brackety.auth.dto.UpdateMeRequest;
import dev.rgal.brackety.auth.email.EmailChangeService;
import dev.rgal.brackety.auth.reauth.ReauthService;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.UUID;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/me")
class MeController {

    private final MeService me;
    private final ProfileService profiles;
    private final AccountDeletionService deletion;
    private final DataExportService export;
    private final EmailChangeService emailChange;
    private final ReauthService reauth;

    MeController(
            MeService me,
            ProfileService profiles,
            AccountDeletionService deletion,
            DataExportService export,
            EmailChangeService emailChange,
            ReauthService reauth) {
        this.me = me;
        this.profiles = profiles;
        this.deletion = deletion;
        this.export = export;
        this.emailChange = emailChange;
        this.reauth = reauth;
    }

    @GetMapping
    MeResponse get(@AuthenticationPrincipal Jwt jwt) {
        return me.get(accountId(jwt));
    }

    @PatchMapping
    MeResponse update(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody UpdateMeRequest request) {
        return me.updateLocale(accountId(jwt), request.locale());
    }

    // The new profile shows in the access token from the next refresh.
    @PostMapping("/profiles")
    @RequiresVerifiedEmail
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void addProfile(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody ProfileRequest request) {
        profiles.add(accountId(jwt), request.type());
    }

    @DeleteMapping("/profiles/{type}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void removeProfile(@AuthenticationPrincipal Jwt jwt, @PathVariable ProfileType type) {
        profiles.remove(accountId(jwt), type);
    }

    @PostMapping("/email")
    @ResponseStatus(HttpStatus.ACCEPTED)
    void changeEmail(
            @AuthenticationPrincipal Jwt jwt,
            @RequestHeader(name = ReauthService.HEADER, required = false) String reauthToken,
            @Valid @RequestBody NewEmailRequest request) {
        reauth.require(accountId(jwt), reauthToken);
        emailChange.request(accountId(jwt), request.newEmail());
    }

    @DeleteMapping
    DeletionResponse delete(
            @AuthenticationPrincipal Jwt jwt,
            @RequestHeader(name = ReauthService.HEADER, required = false) String reauthToken) {
        reauth.require(accountId(jwt), reauthToken);
        return deletion.delete(accountId(jwt));
    }

    @GetMapping("/export")
    ResponseEntity<DataExport> export(
            @AuthenticationPrincipal Jwt jwt,
            @RequestHeader(name = ReauthService.HEADER, required = false) String reauthToken) {
        reauth.require(accountId(jwt), reauthToken);
        var data = export.export(accountId(jwt));
        var fileName = "brackety-data-" + LocalDate.ofInstant(data.exportedAt(), ZoneOffset.UTC) + ".json";
        return ResponseEntity.ok()
                .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment()
                                .filename(fileName)
                                .build()
                                .toString())
                .body(data);
    }

    private static UUID accountId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
