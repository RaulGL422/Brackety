package dev.rgal.brackety.ranking.dto;

import dev.rgal.brackety.ranking.dto.ParticipantRecord.RecordMatch;
import java.util.List;
import java.util.UUID;

/** One person across the league: every phase they entered, with its matches (and their incidents). */
public record LeagueRecord(List<Phase> phases) {

    public record Phase(UUID eventId, int number, String name, List<RecordMatch> matches) {}
}
