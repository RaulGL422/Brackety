package dev.rgal.brackety.league.dto;

import dev.rgal.brackety.event.Discipline;
import dev.rgal.brackety.league.Podium;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** The league an event is a phase of (docs/modulos/liga-fases.md). */
public final class LeagueDtos {

    private LeagueDtos() {}

    /** {@code categoryPodiums}: the categories with their own podium; the rest use {@code podium}. */
    public record LeagueResponse(
            UUID id,
            String name,
            Podium podium,
            List<CategoryPodiumDto> categoryPodiums,
            List<PhaseResponse> phases,
            List<String> categoryNames,
            List<DisciplineResponse> disciplines) {}

    public record CategoryPodiumDto(
            @NotBlank @Size(max = 40) String categoryName,
            @NotNull @Valid Podium podium) {}

    public record PhaseResponse(
            UUID eventId, int number, String name, LocalDate date, Discipline discipline, int participants) {}

    /** {@code available}: has a scoreboard today; the others are declared for later. */
    public record DisciplineResponse(Discipline discipline, boolean available) {}

    public record LeagueRequest(
            @NotBlank @Size(max = 120) String name,
            @NotNull @Valid Podium podium,
            @NotNull @Size(max = 30) List<@NotNull @Valid CategoryPodiumDto> categoryPodiums) {}

    /** The next phase: it copies the mats with their referees, the staff, categories and organizations. */
    public record NewPhaseRequest(
            @NotBlank @Size(max = 120) String name,
            @NotNull LocalDate date,
            @NotNull Discipline discipline,
            @Min(0) @Max(100) int attendancePoints) {}

    /** Someone from another phase of the league not entered in this one; their latest entry. */
    public record Candidate(
            UUID personId,
            String firstName,
            String lastName,
            LocalDate birthDate,
            int age,
            String organizationName,
            String categoryName,
            int lastPhase) {}

    /** {@code guardianConsent}: the guardians of the minors among them agree (needed if any is a minor). */
    public record ReenrolRequest(@NotEmpty @Size(max = 500) List<@NotNull UUID> personIds, boolean guardianConsent) {}

    public record ReenrolResponse(int added) {}
}
