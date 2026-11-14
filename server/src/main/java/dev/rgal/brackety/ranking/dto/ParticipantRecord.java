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
     * null. Warnings and points are their side's; {@code incidents}, each of those warnings and a disqualification.
     */
    public record RecordMatch(
            UUID matchId,
            Integer matNumber,
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
            String endReason,
            List<Incident> incidents) {}

    /**
     * A warning, one-hand warning or disqualification that stands (not undone, not before the match was cancelled).
     * {@code kind}: WARNING, ONE_HAND_WARNING or DISQUALIFICATION. {@code clockMs}: the match clock then.
     * {@code by}: the referee's account. {@code gaveRivalPoint}: a second warning that gave the rival a point.
     */
    public record Incident(String kind, String reason, long clockMs, String by, boolean gaveRivalPoint) {}
}
