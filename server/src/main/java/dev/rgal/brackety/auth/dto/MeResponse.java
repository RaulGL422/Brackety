package dev.rgal.brackety.auth.dto;

import java.time.LocalDate;
import java.util.List;

public record MeResponse(
        String email,
        boolean emailVerified,
        LocalDate birthDate,
        String locale,
        List<ProfileResponse> profiles,
        List<SignInMethodResponse> signInMethods,
        // Let in by QR for one event: the app hides what such an account cannot do.
        boolean temporary,
        // Changed legal texts to accept again before going on (docs/modulos/legal-paginas.md).
        List<PendingConsent> pendingConsents) {}
