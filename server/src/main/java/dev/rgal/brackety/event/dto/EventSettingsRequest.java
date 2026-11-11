package dev.rgal.brackety.event.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * {@code matReferees} has one entry per mat, in mat order (mat 1 first): its size is the number of
 * mats and each entry is the referee's account id, or null for a mat without referee yet.
 * {@code matchSeconds} (30 s to 20 min) and {@code pointsLimit}: null keeps the current value.
 */
public record EventSettingsRequest(
        @NotBlank @Size(max = 120) String name,
        @NotNull LocalDate date,
        @Min(1) @Max(4) int maxGroupsPerMat,
        @NotEmpty @Size(max = 20) List<UUID> matReferees,
        @Min(30) @Max(1200) Integer matchSeconds,
        @Min(1) @Max(99) Integer pointsLimit) {}
