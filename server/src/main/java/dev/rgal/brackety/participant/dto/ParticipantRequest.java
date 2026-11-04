package dev.rgal.brackety.participant.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.UUID;

/** {@code categoryId}: a chosen category of the event, or null to follow the age. */
public record ParticipantRequest(
        @NotBlank @Size(max = 60) String firstName,
        @NotBlank @Size(max = 80) String lastName,
        @NotNull @Past LocalDate birthDate,
        @Min(50) @Max(250) Integer heightCm,
        boolean guardianConsent,
        UUID categoryId) {}
