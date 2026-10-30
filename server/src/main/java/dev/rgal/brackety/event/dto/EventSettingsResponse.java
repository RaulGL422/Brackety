package dev.rgal.brackety.event.dto;

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

    public record CategoryResponse(UUID id, String name, int minAge, int maxAge) {}
}
