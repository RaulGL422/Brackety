package dev.rgal.brackety.auth.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalDate;
import java.util.List;

/** {@code deletesOn} only while the account is pending deletion. */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record MeResponse(
        String email,
        boolean emailVerified,
        LocalDate birthDate,
        String locale,
        List<ProfileResponse> profiles,
        List<SignInMethodResponse> signInMethods,
        LocalDate deletesOn) {}
