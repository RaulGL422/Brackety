package dev.rgal.brackety.grouping.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

/**
 * The order given is the order in the team. {@code ghostIds}: those of them who fill the team in without scoring for
 * it (they may compete elsewhere); null or empty when all are real.
 */
public record CreateTeamRequest(
        @NotEmpty @Size(max = 5) List<@NotNull UUID> participantIds,
        @Size(max = 4) List<@NotNull UUID> ghostIds) {}
