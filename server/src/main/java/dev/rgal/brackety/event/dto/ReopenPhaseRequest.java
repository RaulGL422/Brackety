package dev.rgal.brackety.event.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Why the club reopens a finished phase: kept in its history. */
public record ReopenPhaseRequest(@NotBlank @Size(max = 500) String reason) {}
