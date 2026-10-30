package dev.rgal.brackety.grouping.dto;

import java.util.List;
import java.util.UUID;

public record CreateGroupsResponse(UUID matId, int matNumber, List<Integer> groupNumbers) {}
