package dev.rgal.brackety.eventpackage;

import dev.rgal.brackety.event.Discipline;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.league.Podium;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * The {@code .brackety} file (docs/modulos/servidor-local.md): an event ready to run on another server. Accounts are
 * named by username (their login); no passwords or other account data. Version 2 adds the league, the organizations,
 * a stable id per person and the results (groups, teams, matches and their actions), all optional so version 1 files
 * still load.
 */
public record EventPackage(
        int schemaVersion,
        Instant exportedAt,
        @NotNull @Valid Settings event,
        @Valid LeagueEntry league,
        @NotNull @Valid Owner owner,
        @NotNull List<@NotNull @Valid StaffMember> staff,
        @NotNull List<@NotNull @Valid Category> categories,
        @Size(max = 100) List<@NotNull @Valid OrganizationEntry> organizations,
        @NotNull @Size(max = 20) List<@NotNull @Valid MatEntry> mats,
        @NotNull List<@NotNull @Valid ParticipantEntry> participants,
        @Valid EventResults results,
        @Size(max = 100) List<@NotNull @Valid StaffName> staffNames,
        @Valid RulebookEntry rulebook) {

    public static final int SCHEMA_VERSION = 2;

    /** The phase's rulebook PDF, in base64; absent when it has none or in files from before rulebooks. */
    public record RulebookEntry(
            @NotBlank @Size(max = 200) String fileName,
            @NotBlank String pdf) {}

    /** The person behind a staff account (set by the club); absent in files from before names existed. */
    public record StaffName(
            @NotBlank @Size(max = 254) String username,
            @NotBlank @Size(max = 80) String name) {}

    public List<StaffName> staffNamesOrEmpty() {
        return staffNames == null ? List.of() : staffNames;
    }

    public List<OrganizationEntry> organizationsOrEmpty() {
        return organizations == null ? List.of() : organizations;
    }

    /**
     * {@code originId}: the event on the server it was first exported from (the club's server), so its results can
     * go back there. The team rules and the rest are null in a package from before they existed: defaults then.
     */
    public record Settings(
            @NotBlank @Size(max = 120) String name,
            @NotNull LocalDate date,
            @Min(1) @Max(4) int maxGroupsPerMat,
            @Min(1) int matchSeconds,
            @Min(1) int pointsLimit,
            @Min(0) int changeoverSeconds,
            @Min(0) int attendancePoints,
            UUID originId,
            @Min(1) Integer teamMatchSeconds,
            @Min(0) Integer teamPointsLimit,
            @Min(0) Integer minRestSeconds) {}

    public record LeagueEntry(
            @NotBlank @Size(max = 120) String name,
            @Min(1) int phaseNumber,
            @NotNull Discipline discipline,
            @NotNull @Valid Podium podium,
            @NotNull List<@NotNull @Valid CategoryPodiumEntry> categoryPodiums) {}

    public record CategoryPodiumEntry(
            @NotBlank @Size(max = 40) String categoryName,
            @NotNull @Valid Podium podium) {}

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

    public record OrganizationEntry(
            @NotBlank @Size(max = 120) String name,
            @Size(max = 20) String shortName) {}

    public record MatEntry(@Min(1) int number, String refereeUsername) {}

    /**
     * {@code categoryName}: the category chosen for them, or null to follow their age. {@code personId}: the same
     * person in every phase and on every server; results name participants by it.
     */
    public record ParticipantEntry(
            @NotBlank @Size(max = 60) String firstName,
            @NotBlank @Size(max = 80) String lastName,
            @NotNull LocalDate birthDate,
            @Min(50) @Max(250) Integer heightCm,
            boolean guardianConsent,
            String categoryName,
            UUID personId,
            String organizationName) {}
}
