package dev.rgal.brackety.grouping.dto;

import java.util.List;
import java.util.UUID;

/**
 * {@code groupNumber}, {@code matNumber} and {@code groupId} are null until the team is in a group;
 * {@code groupStarted}: a match of that group has started, so the helper can no longer undo it.
 */
public record TeamResponse(
        UUID id,
        int number,
        List<Member> members,
        Integer groupNumber,
        Integer matNumber,
        UUID groupId,
        boolean groupStarted) {

    /** {@code ghost}: fills the team in without scoring for it. */
    public record Member(UUID participantId, String firstName, String lastName, boolean ghost) {}
}
