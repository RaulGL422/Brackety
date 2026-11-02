package dev.rgal.brackety.grouping.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

/** The order given is the order in the team. */
public record CreateTeamRequest(@NotEmpty @Size(max = 5) List<@NotNull UUID> participantIds) {}
