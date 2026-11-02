package dev.rgal.brackety.participant.importing.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.util.List;

/** {@code consentVersion}: the consent text the club accepted; it must be the current one. */
public record ImportRequest(@NotEmpty List<@Valid @NotNull ImportRow> rows, String consentVersion) {}
