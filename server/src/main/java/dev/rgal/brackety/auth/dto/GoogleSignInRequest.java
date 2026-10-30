package dev.rgal.brackety.auth.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** {@code registration} is only needed the first time, after the API answered REGISTRATION_REQUIRED. */
public record GoogleSignInRequest(
        @NotBlank @Size(max = 4096) String idToken, @Valid RegistrationDetails registration) {

    @Override
    public String toString() {
        return "GoogleSignInRequest[registration=" + registration + "]";
    }
}
