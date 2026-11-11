package dev.rgal.brackety.scoreboard.dto;

/**
 * What an import of rescued device actions did: {@code applied} now, {@code duplicates} the server already had
 * (same {@code opId}), {@code inReview} kept for the club's review, {@code skipped} refused for good.
 */
public record OfflineImportResponse(int applied, int duplicates, int inReview, int skipped) {}
