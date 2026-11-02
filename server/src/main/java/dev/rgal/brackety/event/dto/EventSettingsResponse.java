package dev.rgal.brackety.event.dto;

import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategory.Format;
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
        List<CategoryResponse> categories) {

    public record MatSettings(UUID id, int number, UUID refereeId) {}

    public record StaffMember(UUID id, String username) {}

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
