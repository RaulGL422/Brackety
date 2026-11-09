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
 * disqualifications. {@code knownEvents} (required, so two tabs pressing at once do not both count): how
 * many non-automatic actions the sender knew before this one. From the Android queue (docs/modulos/offline.md): {@code opId} is the action's id and
 * {@code at} when it happened on the device. Without {@code opId}, {@code at} is ignored.
 */
public record MatchEventRequest(
        @NotNull MatchEventType type,
        Side side,
        @Size(max = 200) String reason,
        UUID opId,
        Instant at,
        @PositiveOrZero Integer knownEvents) {}
