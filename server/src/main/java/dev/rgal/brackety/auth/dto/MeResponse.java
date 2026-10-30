package dev.rgal.brackety.auth.dto;

import java.time.LocalDate;
import java.util.List;

public record MeResponse(
        String email,
        boolean emailVerified,
        LocalDate birthDate,
        String locale,
        List<ProfileResponse> profiles,
        List<SignInMethodResponse> signInMethods) {}
