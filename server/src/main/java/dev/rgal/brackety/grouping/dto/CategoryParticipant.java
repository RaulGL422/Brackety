package dev.rgal.brackety.grouping.dto;

import java.util.UUID;

/**
 * {@code groupNumber} and {@code matNumber} are null until the participant is in a group, directly
 * or through their team; {@code teamNumber} until they are in a team.
 */
public record CategoryParticipant(
        UUID id,
        String firstName,
        String lastName,
        Integer heightCm,
        int age,
        Integer groupNumber,
        Integer matNumber,
        Integer teamNumber) {}
