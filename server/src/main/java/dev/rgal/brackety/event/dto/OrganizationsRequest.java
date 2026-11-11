package dev.rgal.brackety.event.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

/** The event's whole organization list: those left out are removed. */
public record OrganizationsRequest(@NotNull @Size(max = 100) List<@Valid @NotNull OrganizationRequest> organizations) {}
