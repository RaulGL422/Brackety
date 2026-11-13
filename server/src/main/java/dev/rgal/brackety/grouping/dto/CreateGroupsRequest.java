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
     * A group of 4 participants ({@code participantIds} plus up to 3 {@code ghostIds}) or, in a team category, of 4
     * teams: {@code teamIds} (1 to 4) plus up to 3 wildcard teams, each made of the participants in
     * {@code ghostTeams} ({@code ghostTeam}: one wildcard team, as older apps send it). The order given is the order
     * in the group.
     */
    public record GroupRequest(
            @Size(max = 4) List<@NotNull UUID> participantIds,
            @Size(max = 3) List<@NotNull UUID> ghostIds,
            @Size(max = 4) List<@NotNull UUID> teamIds,
            @Size(max = 3) List<@NotNull UUID> ghostTeam,
            @Size(max = 3) List<@NotNull @Size(max = 3) List<@NotNull UUID>> ghostTeams) {

        public List<UUID> ghosts() {
            return ghostIds == null ? List.of() : ghostIds;
        }

        public List<List<UUID>> wildcardTeams() {
            var all = new java.util.ArrayList<List<UUID>>();
            if (ghostTeam != null && !ghostTeam.isEmpty()) {
                all.add(ghostTeam);
            }
            if (ghostTeams != null) {
                all.addAll(ghostTeams);
            }
            return all;
        }

        public boolean isOfTeams() {
            return teamIds != null && !teamIds.isEmpty();
        }
    }
}
