package dev.rgal.brackety.scoreboard.dto;

import dev.rgal.brackety.scoreboard.MatchEventType;
import dev.rgal.brackety.scoreboard.Side;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;

/**
 * {@code side} for points, warnings and disqualifications; {@code reason} required for warnings and
 * disqualifications. From the Android queue (docs/modulos/offline.md): {@code opId} is the action's id,
 * {@code at} when it happened on the device and {@code knownEvents} how many non-automatic actions the
 * device knew before it (required with {@code opId}). Without {@code opId}, {@code at} is ignored.
 */
public record MatchEventRequest(
        @NotNull MatchEventType type,
        Side side,
        @Size(max = 200) String reason,
        UUID opId,
        Instant at,
        @PositiveOrZero Integer knownEvents) {}
