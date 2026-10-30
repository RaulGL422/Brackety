package dev.rgal.brackety.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record IdTokenRequest(@NotBlank @Size(max = 4096) String idToken) {

    @Override
    public String toString() {
        return "IdTokenRequest[]";
    }
}
