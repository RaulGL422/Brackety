package dev.rgal.brackety.event.dto;

import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategory.Format;
import dev.rgal.brackety.event.EventOrganization;
import dev.rgal.brackety.event.EventRole;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public record EventSettingsResponse(
        String name,
        LocalDate date,
        int maxGroupsPerMat,
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
        int minRestSeconds) {

    public record OrganizationResponse(UUID id, String name, String shortName) {

        public static OrganizationResponse of(EventOrganization o) {
            return new OrganizationResponse(o.getId(), o.getName(), o.getShortName());
        }
    }

    public record MatSettings(UUID id, int number, UUID refereeId) {}

    /**
     * {@code personName}: who is behind the account in this event, set by the club; null until then. {@code roles}:
     * the account's roles in the event.
     */
    public record StaffMember(UUID id, String username, String personName, List<EventRole> roles) {}

    /** {@code teamSize} is null in an individual category. */
    public record CategoryResponse(
            UUID id, String name, int minAge, int maxAge, Format format, Integer teamSize, int groupSize) {

        public static CategoryResponse of(EventCategory c) {
            return new CategoryResponse(
                    c.getId(),
                    c.getName(),
                    c.getMinAge(),
                    c.getMaxAge(),
                    c.getFormat(),
                    c.getTeamSize(),
                    c.getGroupSize());
        }
    }
}
