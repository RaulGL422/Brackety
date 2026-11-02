package dev.rgal.brackety.grouping.dto;

import dev.rgal.brackety.grouping.Match;
import java.util.List;
import java.util.UUID;

/** What the referee sees on a mat; {@code recommendedMatchId} is null when nothing can start. */
public record MatBoardResponse(
        UUID matId, int matNumber, List<BoardGroup> groups, List<BoardMatch> matches, UUID recommendedMatchId) {

    /**
     * A participant ({@code participantId}) or a team ({@code teamId}, {@code teamNumber}); {@code members}
     * are the team's names, or the participant's own.
     */
    public record Fighter(
            UUID participantId, String name, boolean ghost, UUID teamId, Integer teamNumber, List<String> members) {}

    public record BoardGroup(UUID id, int number, String categoryName, List<Fighter> members) {}

    /** {@code available}: neither fighter is in a match in progress on any mat. */
    public record BoardMatch(
            UUID id,
            UUID groupId,
            int groupNumber,
            int order,
            Fighter red,
            Fighter blue,
            Match.Status status,
            int redScore,
            int blueScore,
            boolean available) {}
}
