package dev.rgal.brackety.grouping.dto;

import java.util.UUID;

/**
 * {@code groupNumber} and {@code matNumber} are null until the participant is in a group, directly
 * or through their team; {@code teamNumber} until they are in a team. {@code groupId}: their group;
 * {@code groupStarted}: a match of it has started, so the helper can no longer undo it. {@code groupCreatedBy}: who
 * made the group ("Ana López (ayudante1)", or the sign-in alone).
 */
public record CategoryParticipant(
        UUID id,
        String firstName,
        String lastName,
        Integer heightCm,
        int age,
        Integer groupNumber,
        Integer matNumber,
        Integer teamNumber,
        UUID groupId,
        boolean groupStarted,
        String groupCreatedBy) {}
