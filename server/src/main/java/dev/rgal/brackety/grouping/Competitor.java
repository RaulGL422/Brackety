package dev.rgal.brackety.grouping;

import java.util.List;
import java.util.UUID;

/**
 * Who stands on one side of a match: a participant, or a team with its members. {@code name} is
 * the participant's full name or "Equipo N"; clients build their own label from {@code teamNumber}.
 * {@code participantIds}: everyone who fights; {@code scorerIds}: those the points go to (a team's
 * ghost members fill it in but do not score for it).
 */
public record Competitor(
        UUID id,
        String name,
        Integer teamNumber,
        List<UUID> participantIds,
        List<String> memberNames,
        List<UUID> scorerIds) {

    public boolean isTeam() {
        return teamNumber != null;
    }
}
