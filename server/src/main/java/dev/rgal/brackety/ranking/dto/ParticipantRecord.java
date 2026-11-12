package dev.rgal.brackety.ranking.dto;

import java.util.List;
import java.util.UUID;

/**
 * One participant's day for the club: their row of the phase standings and every match they fight, directly, with
 * their team or as a ghost, in the order they come on each mat.
 */
public record ParticipantRecord(StandingRow standing, List<RecordMatch> matches) {

    /**
     * {@code side}: RED or BLUE. {@code asGhost}: they (or their team) fill the group in and score nothing here.
     * {@code team}: the team's number when they fight with one. {@code endReason}: POINTS, TIME, DISQUALIFICATION or
     * null. Warnings and points are their side's.
     */
    public record RecordMatch(
            UUID matchId,
            int matNumber,
            int groupNumber,
            String status,
            String side,
            boolean asGhost,
            Integer team,
            String rival,
            int points,
            int rivalPoints,
            int warnings,
            int oneHandWarnings,
            boolean disqualified,
            boolean rivalDisqualified,
            String endReason) {}
}
