package dev.rgal.brackety.eventpackage;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * What happened in the event: teams, groups, matches and every scoreboard action. Participants are named by their
 * {@code personId}, teams by number, mats by number, categories by name and accounts by username, so the results can
 * be imported into the same event on another server.
 */
public record EventResults(
        @NotNull List<@NotNull @Valid TeamEntry> teams,
        @NotNull List<@NotNull @Valid GroupEntry> groups,
        @NotNull List<@NotNull @Valid MatchEntry> matches) {

    /**
     * {@code ghostMemberPersonIds}: members of a real team who fill it in without scoring for it; absent in files from
     * before they existed.
     */
    public record TeamEntry(
            int number,
            @NotNull String categoryName,
            boolean ghost,
            String createdBy,
            @NotNull Instant createdAt,
            @NotNull List<@NotNull UUID> memberPersonIds,
            List<@NotNull UUID> ghostMemberPersonIds) {}

    /** {@code matNumber}: null for a group of teams (its matches go to the free mats). */
    public record GroupEntry(
            int number,
            @NotNull String categoryName,
            Integer matNumber,
            String createdBy,
            @NotNull Instant createdAt,
            @NotNull List<@NotNull @Valid MemberEntry> members) {}

    /** A participant ({@code personId}) or a team ({@code teamNumber}). */
    public record MemberEntry(int position, boolean ghost, UUID personId, Integer teamNumber) {}

    public record SideEntry(UUID personId, Integer teamNumber) {}

    /** {@code matNumber}: null for a team match not started (in the pool). */
    public record MatchEntry(
            int groupNumber,
            int orderIndex,
            Integer matNumber,
            @NotNull SideEntry red,
            @NotNull SideEntry blue,
            @NotNull String status,
            int redScore,
            int blueScore,
            Instant startedAt,
            Instant finishedAt,
            long elapsedMs,
            Instant runningSince,
            String disqualifiedSide,
            String reviewReason,
            @NotNull List<@NotNull @Valid ActionEntry> actions) {}

    /** {@code undoesPosition}: for an undo, the position of the action it undoes in the same match. */
    public record ActionEntry(
            int position,
            @NotNull String type,
            String side,
            String reason,
            Integer undoesPosition,
            String actor,
            boolean automatic,
            @NotNull Instant at,
            long clockMs) {}

    public int actionCount() {
        return matches.stream().mapToInt(m -> m.actions().size()).sum();
    }

    public boolean isEmpty() {
        return teams.isEmpty() && groups.isEmpty() && matches.isEmpty();
    }
}
