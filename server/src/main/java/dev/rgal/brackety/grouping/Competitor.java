package dev.rgal.brackety.grouping;

import java.util.List;
import java.util.UUID;

/**
 * Who stands on one side of a match: a participant, or a team with its members. {@code name} is
 * the participant's full name or "Equipo N"; clients build their own label from {@code teamNumber}.
 */
public record Competitor(
        UUID id, String name, Integer teamNumber, List<UUID> participantIds, List<String> memberNames) {

    public boolean isTeam() {
        return teamNumber != null;
    }
}
