package dev.rgal.brackety.grouping.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** The control panel's requests (MatchControlService), the same for the club and the superadmin. */
public final class ControlRequests {

    private ControlRequests() {}

    public record MoveRequest(@NotNull UUID matId) {}

    /** Every pending match of the group, in the new order. */
    public record OrderRequest(@NotEmpty List<@NotNull UUID> matchIds) {}

    /** Group id → the mat chosen for it; a group left out goes to the mat free first. */
    public record DisableMatRequest(Map<@NotNull UUID, @NotNull UUID> groupMats) {

        /** The request may have no body: every group goes to the mat free first. */
        public static Map<UUID, UUID> chosen(DisableMatRequest request) {
            return request == null || request.groupMats() == null ? Map.of() : request.groupMats();
        }
    }

    public record TeamMoveRequest(
            @NotNull UUID participantId,
            @NotNull UUID fromTeamId,
            @NotNull UUID toTeamId) {}
}
