package dev.rgal.brackety.grouping.dto;

import java.util.List;
import java.util.UUID;

/** {@code groupIds}: in the order of {@code groupNumbers}, so the helper can undo one at once. */
public record CreateGroupsResponse(UUID matId, int matNumber, List<Integer> groupNumbers, List<UUID> groupIds) {}
