package dev.rgal.brackety.event.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/** {@code id} is null for a new organization. */
public record OrganizationRequest(
        UUID id,
        @NotBlank @Size(max = 120) String name,
        @Size(max = 20) String shortName) {}
