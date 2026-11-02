package dev.rgal.brackety.grouping.dto;

import java.util.List;
import java.util.UUID;

/** {@code groupNumber} and {@code matNumber} are null until the team is in a group. */
public record TeamResponse(UUID id, int number, List<Member> members, Integer groupNumber, Integer matNumber) {

    public record Member(UUID participantId, String firstName, String lastName) {}
}
