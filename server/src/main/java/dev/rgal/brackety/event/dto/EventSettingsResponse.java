package dev.rgal.brackety.event.dto;

import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategory.Format;
import dev.rgal.brackety.event.EventOrganization;
import dev.rgal.brackety.event.EventPermission;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.ScoringRules;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import java.util.UUID;

public record EventSettingsResponse(
        String name,
        LocalDate date,
        int matchSeconds,
        int pointsLimit,
        List<MatSettings> mats,
        List<StaffMember> referees,
        List<StaffMember> staff,
        List<CategoryResponse> categories,
        List<OrganizationResponse> organizations,
        int attendancePoints,
        int phaseNumber,
        String discipline,
        int teamMatchSeconds,
        int teamPointsLimit,
        int minRestSeconds,
        MeasureRules measures,
        WarningReasons warningReasons,
        ScoringRules scoring) {

    /** For a helper: everything but who the staff are and their sign-ins. */
    public EventSettingsResponse withoutStaff() {
        return new EventSettingsResponse(
                name,
                date,
                matchSeconds,
                pointsLimit,
                mats,
                List.of(),
                List.of(),
                categories,
                organizations,
                attendancePoints,
                phaseNumber,
                discipline,
                teamMatchSeconds,
                teamPointsLimit,
                minRestSeconds,
                measures,
                warningReasons,
                scoring);
    }

    public record OrganizationResponse(UUID id, String name, String shortName) {

        public static OrganizationResponse of(EventOrganization o) {
            return new OrganizationResponse(o.getId(), o.getName(), o.getShortName());
        }
    }

    public record MatSettings(UUID id, int number, UUID refereeId) {}

    /**
     * {@code personName}: who is behind the account in this event, set by the club; null until then. {@code roles}:
     * the account's roles in the event. {@code permissions}: what the club lets them do (F1-7 C).
     */
    public record StaffMember(
            UUID id, String username, String personName, List<EventRole> roles, Set<EventPermission> permissions) {}

    /** {@code teamSize} is null in an individual category. */
    public record CategoryResponse(
            UUID id,
            String name,
            int minAge,
            int maxAge,
            Format format,
            Integer teamSize,
            int minGroupSize,
            int maxGroupSize,
            boolean returnLeg,
            Integer matchSeconds) {

        public static CategoryResponse of(EventCategory c) {
            return new CategoryResponse(
                    c.getId(),
                    c.getName(),
                    c.getMinAge(),
                    c.getMaxAge(),
                    c.getFormat(),
                    c.getTeamSize(),
                    c.getMinGroupSize(),
                    c.getMaxGroupSize(),
                    c.isReturnLeg(),
                    c.getMatchSeconds());
        }
    }
}
