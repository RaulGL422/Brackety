package dev.rgal.brackety.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record TokenRequest(@NotBlank @Size(max = 128) String token) {

    @Override
    public String toString() {
        return "TokenRequest[]";
    }
}
