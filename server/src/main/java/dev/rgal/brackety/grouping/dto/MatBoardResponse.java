package dev.rgal.brackety.grouping.dto;

import dev.rgal.brackety.grouping.Match;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * What the referee sees on a mat; {@code recommendedMatchId} is null when nothing can start. {@code teamPool}: the
 * mat has no individual match pending, so it takes team matches from the pool shared by every such mat; those are
 * in {@code matches} too.
 */
public record MatBoardResponse(
        UUID matId,
        int matNumber,
        List<BoardGroup> groups,
        List<BoardMatch> matches,
        UUID recommendedMatchId,
        boolean teamPool,
        UUID eventId) {

    /**
     * A participant ({@code participantId}) or a team ({@code teamId}, {@code teamNumber}); {@code members}
     * are the team's names, or the participant's own.
     */
    public record Fighter(
            UUID participantId, String name, boolean ghost, UUID teamId, Integer teamNumber, List<String> members) {}

    /** {@code createdBy}: who made the group ("Ana López (ayudante1)", or the sign-in alone). */
    public record BoardGroup(UUID id, int number, String categoryName, List<Fighter> members, String createdBy) {}

    /**
     * {@code available}: it can start now. {@code waitReason} says why not: REVIEW (an offline action clashed and
     * the club has to apply or discard it), BUSY (someone is fighting on a mat) or RESTING (someone has not had the
     * least rest; until {@code readyAt}). OTHER_MAT (proposed to mat {@code otherMatNumber}) is only a hint: it stays
     * available, so a stalled mat never holds it. {@code pool}: a team match waiting for a free mat.
     */
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
            boolean available,
            boolean inReview,
            String waitReason,
            Instant readyAt,
            Integer otherMatNumber,
            boolean pool,
            Corner redCorner,
            Corner blueCorner) {}

    /**
     * Where a pending match's fighter (all of a team's people) is now, so the referee knows when to call them:
     * {@code fightingOnMat} if one is fighting there, {@code freeAt} when all are free and rested (an estimate while
     * fighting; null if they are already), {@code pendingMats} the mats where they still have other matches, one
     * entry per match.
     */
    public record Corner(Integer fightingOnMat, Instant freeAt, List<Integer> pendingMats) {}
}
