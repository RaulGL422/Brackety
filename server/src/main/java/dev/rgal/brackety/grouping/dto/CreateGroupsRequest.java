package dev.rgal.brackety.grouping.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

/**
 * One or more groups of one category, all sent to the same mat: {@code matId} if the helper picked
 * one, otherwise the one that will be free first.
 */
public record CreateGroupsRequest(
        @NotNull UUID categoryId, @NotEmpty @Size(max = 4) List<@Valid @NotNull GroupRequest> groups, UUID matId) {

    /**
     * A group of participants (4, or 3 plus {@code ghostId}) or, in a team category, of teams (4, or
     * 3 plus a ghost team made of the {@code ghostTeam} participants). The order given is the order
     * in the group.
     */
    public record GroupRequest(
            @Size(max = 4) List<@NotNull UUID> participantIds,
            UUID ghostId,
            @Size(max = 4) List<@NotNull UUID> teamIds,
            @Size(max = 5) List<@NotNull UUID> ghostTeam) {

        public boolean isOfTeams() {
            return teamIds != null && !teamIds.isEmpty();
        }
    }
}
