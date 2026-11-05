package dev.rgal.brackety.scoreboard.dto;

/** {@code skipped}: actions the rules refused when applying; always 0 when discarding. */
public record ReviewResponse(MatchView match, int applied, int skipped) {}
