package dev.rgal.brackety.participant.importing.dto;

import java.util.List;

/** {@code registered} is 0 and {@code rows} carry the errors when nothing was registered. */
public record ImportResult(int registered, List<CheckedRow> rows) {}
