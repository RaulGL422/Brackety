package dev.rgal.brackety.grouping.dto;

import java.util.UUID;

/** {@code grouped}: participants already in a group (not counting ghosts). */
public record CategorySummary(UUID id, String name, int minAge, int maxAge, int participants, int grouped) {}
