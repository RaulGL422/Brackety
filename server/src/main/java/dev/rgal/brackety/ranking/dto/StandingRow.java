package dev.rgal.brackety.ranking.dto;

import java.util.UUID;

/**
 * {@code attendancePoints}: given once the participant is in a group (not as a ghost).
 * {@code matchPoints}: what they (or their team) scored in finished matches, except as a ghost or when
 * disqualified. {@code teamNumber}: their real team, or null. {@code personId}: the same person in every phase.
 * Equal totals share {@code position}. {@code wins} and {@code classificationPoints}: only when the event's sport ranks
 * by them (grappling), else null.
 */
public record StandingRow(
        int position,
        UUID participantId,
        String firstName,
        String lastName,
        int age,
        UUID categoryId,
        String categoryName,
        int attendancePoints,
        int matchPoints,
        int total,
        int matches,
        Integer teamNumber,
        UUID personId,
        String organizationName,
        Integer wins,
        Integer classificationPoints) {

    public StandingRow withPosition(int position) {
        return new StandingRow(
                position,
                participantId,
                firstName,
                lastName,
                age,
                categoryId,
                categoryName,
                attendancePoints,
                matchPoints,
                total,
                matches,
                teamNumber,
                personId,
                organizationName,
                wins,
                classificationPoints);
    }
}
