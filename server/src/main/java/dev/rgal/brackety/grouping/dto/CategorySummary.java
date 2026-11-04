package dev.rgal.brackety.grouping.dto;

import dev.rgal.brackety.event.EventCategory.Format;
import java.util.UUID;

/**
 * {@code grouped}: participants competing in a group, directly or through their team (not counting
 * ghosts). {@code inTeams}: participants in a real team. {@code teams}: real teams.
 */
public record CategorySummary(
        UUID id,
        String name,
        int minAge,
        int maxAge,
        int participants,
        int grouped,
        Format format,
        Integer teamSize,
        int inTeams,
        int teams) {}
