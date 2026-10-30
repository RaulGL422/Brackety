package dev.rgal.brackety.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record NewEmailRequest(
        @NotBlank @Email @Size(max = 254) String newEmail) {

    @Override
    public String toString() {
        return "NewEmailRequest[]";
    }
}
