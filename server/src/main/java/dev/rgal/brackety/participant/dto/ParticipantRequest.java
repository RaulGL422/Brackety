package dev.rgal.brackety.participant.dto;

import dev.rgal.brackety.participant.Sex;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * {@code categoryId}: a chosen category of the event, or null to follow the age. {@code organizationId}: one of
 * the event's organizations, or null. {@code heightCm} and {@code weightKg}: measured for this event, or null.
 */
public record ParticipantRequest(
        @NotBlank @Size(max = 60) String firstName,
        @NotBlank @Size(max = 80) String lastName,
        @NotNull @Past LocalDate birthDate,
        @NotNull Sex sex,
        @Min(50) @Max(250) Integer heightCm,

        @DecimalMin("10.0") @DecimalMax("250.0") @Digits(integer = 3, fraction = 1)
        BigDecimal weightKg,

        boolean guardianConsent,
        UUID categoryId,
        UUID organizationId) {}
