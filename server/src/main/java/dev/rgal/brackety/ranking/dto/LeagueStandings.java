package dev.rgal.brackety.ranking.dto;

import java.util.List;
import java.util.UUID;

/**
 * The league's accumulated standings: one row per person, ranked inside their category (the one of their latest
 * phase). {@code phases} of a row follow {@code phases} of the league; null where they did not enter. {@code medal}:
 * 1, 2 or 3 by the category's podium, or null. {@code warnings} (both kinds) and {@code disqualifications}: in every
 * match of the league they fought, also as a wildcard; in a team match, the team's count for each member.
 * {@code eventId} and {@code participantId}: their entry in the latest phase they are in, to open their record.
 */
public record LeagueStandings(List<Phase> phases, List<Row> rows) {

    public record Phase(UUID eventId, int number, String name) {}

    public record PhasePoints(int attendancePoints, int matchPoints) {

        public int total() {
            return attendancePoints + matchPoints;
        }
    }

    public record Row(
            String categoryName,
            int position,
            Integer medal,
            UUID personId,
            String firstName,
            String lastName,
            String organizationName,
            List<PhasePoints> phases,
            int total,
            int warnings,
            int disqualifications,
            UUID eventId,
            UUID participantId) {}
}
