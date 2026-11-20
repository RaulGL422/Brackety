package dev.rgal.brackety.event.dto;

import dev.rgal.brackety.event.EventCategory.Format;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/**
 * {@code id} is null for a new category; {@code teamSize} only for TEAM; {@code matchSeconds} only when the category's
 * matches last other than its modality's (grappling: 4 min for U13, U15 and veterans).
 */
public record CategoryRequest(
        UUID id,
        @NotBlank @Size(max = 40) String name,
        @Min(0) @Max(120) int minAge,
        @Min(0) @Max(120) int maxAge,
        @NotNull Format format,
        @Min(2) @Max(5) Integer teamSize,
        int groupSize,
        @Min(30) @Max(1200) Integer matchSeconds) {}
