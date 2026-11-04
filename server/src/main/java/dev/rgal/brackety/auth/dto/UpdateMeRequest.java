package dev.rgal.brackety.auth.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

public record UpdateMeRequest(
        @NotNull @Pattern(regexp = "es|en") String locale) {}
