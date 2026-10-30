package dev.rgal.brackety.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record ResetPasswordRequest(
        @NotBlank @Size(max = 128) String token,
        @NotNull @Size(min = 10, max = 128) String newPassword) {

    @Override
    public String toString() {
        return "ResetPasswordRequest[]";
    }
}
