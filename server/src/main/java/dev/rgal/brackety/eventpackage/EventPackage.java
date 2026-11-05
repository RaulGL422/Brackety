package dev.rgal.brackety.eventpackage;

import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventRole;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * The {@code .brackety} file (docs/modulos/servidor-local.md): an event ready to run on another server, with no
 * ids, groups, matches or account data beyond the staff usernames. Accounts are named by username (their login).
 */
public record EventPackage(
        int schemaVersion,
        Instant exportedAt,
        @NotNull @Valid Settings event,
        @NotNull @Valid Owner owner,
        @NotNull List<@NotNull @Valid StaffMember> staff,
        @NotNull List<@NotNull @Valid Category> categories,
        @NotNull @Size(max = 20) List<@NotNull @Valid MatEntry> mats,
        @NotNull List<@NotNull @Valid ParticipantEntry> participants) {

    public static final int SCHEMA_VERSION = 1;

    public record Settings(
            @NotBlank @Size(max = 120) String name,
            @NotNull LocalDate date,
            @Min(1) @Max(4) int maxGroupsPerMat,
            @Min(1) int matchSeconds,
            @Min(1) int pointsLimit,
            @Min(0) int changeoverSeconds,
            @Min(0) int attendancePoints) {}

    /** The organization is null for an organizer created before it was asked for. */
    public record Owner(
            @NotBlank @Size(max = 254) String username,
            @Size(max = 200) String organizationName,
            @Size(max = 9) String taxId) {}

    public record StaffMember(
            @NotBlank @Size(max = 254) String username,
            @NotNull EventRole role) {}

    /** {@code teamSize}: null for an individual category. */
    public record Category(
            @NotBlank @Size(max = 40) String name,
            @Min(0) @Max(120) int minAge,
            @Min(0) @Max(120) int maxAge,
            @NotNull EventCategory.Format format,
            @Min(2) @Max(5) Integer teamSize) {}

    public record MatEntry(@Min(1) int number, String refereeUsername) {}

    /** {@code categoryName}: the category chosen for them, or null to follow their age. */
    public record ParticipantEntry(
            @NotBlank @Size(max = 60) String firstName,
            @NotBlank @Size(max = 80) String lastName,
            @NotNull LocalDate birthDate,
            @Min(50) @Max(250) Integer heightCm,
            boolean guardianConsent,
            String categoryName) {}
}
