package dev.rgal.brackety.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RestoreRequest(@NotBlank @Size(max = 2048) String restoreToken) {

    @Override
    public String toString() {
        return "RestoreRequest[]";
    }
}
