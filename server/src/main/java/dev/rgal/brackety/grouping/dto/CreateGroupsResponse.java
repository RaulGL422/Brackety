package dev.rgal.brackety.grouping.dto;

import java.util.List;
import java.util.UUID;

/**
 * {@code groupIds}: in the order of {@code groupNumbers}, so the helper can undo one at once. {@code matId} and
 * {@code matNumber} are null for groups of teams: their matches go to whichever mat is free of individual matches.
 */
public record CreateGroupsResponse(UUID matId, Integer matNumber, List<Integer> groupNumbers, List<UUID> groupIds) {}
