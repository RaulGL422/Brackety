package dev.rgal.brackety.auth.dto;

import dev.rgal.brackety.auth.account.ProfileType;
import jakarta.validation.constraints.NotNull;

public record ProfileRequest(@NotNull ProfileType type) {}
