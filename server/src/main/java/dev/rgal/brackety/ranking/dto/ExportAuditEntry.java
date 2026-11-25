package dev.rgal.brackety.ranking.dto;

import java.time.Instant;

/** A download with personal data, for the club: who, when, which sheet and which personal columns. */
public record ExportAuditEntry(String account, Instant at, String sheet, String columns) {}
