package dev.rgal.brackety.scoreboard.dto;

import dev.rgal.brackety.scoreboard.MatchEventType;
import dev.rgal.brackety.scoreboard.Side;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** {@code side} for points, warnings and disqualifications; {@code reason} required for warnings and disqualifications. */
public record MatchEventRequest(
        @NotNull MatchEventType type,
        Side side,
        @Size(max = 200) String reason) {}
