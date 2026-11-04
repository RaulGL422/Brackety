package dev.rgal.brackety.auth.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

/** {@code refreshToken} is null for web clients: they get it as an httpOnly cookie instead. */
public record TokenResponse(
        String accessToken,
        long expiresIn,
        @JsonInclude(JsonInclude.Include.NON_NULL) String refreshToken,
        boolean emailVerified) {}
