package dev.rgal.brackety.grouping.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

/** One or more groups of one category, all sent to the same mat. */
public record CreateGroupsRequest(
        @NotNull UUID categoryId, @NotEmpty @Size(max = 4) List<@Valid @NotNull GroupRequest> groups) {

    /** 4 participants, or 3 plus a ghost; the order given is the order in the group. */
    public record GroupRequest(
            @NotNull @Size(min = 3, max = 4) List<@NotNull UUID> participantIds, UUID ghostId) {}
}
