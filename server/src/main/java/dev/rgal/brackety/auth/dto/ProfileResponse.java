package dev.rgal.brackety.auth.dto;

import dev.rgal.brackety.auth.account.ProfileType;

/** {@code validated} by the superadmin; only meaningful for organizers. */
public record ProfileResponse(ProfileType type, boolean validated) {}
