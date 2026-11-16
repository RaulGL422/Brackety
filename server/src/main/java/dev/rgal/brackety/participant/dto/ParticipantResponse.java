package dev.rgal.brackety.participant.dto;

import dev.rgal.brackety.participant.Sex;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * {@code categoryId}: the category they compete in, null when none covers their age.
 * {@code chosenCategoryId}: set when it was chosen instead of following the age.
 * {@code personId}: the same person in every phase of the league. {@code sex}: null only for people entered before
 * it was asked. {@code heightCm} and {@code weightKg}: measured for this event, or null.
 */
public record ParticipantResponse(
        UUID id,
        String firstName,
        String lastName,
        LocalDate birthDate,
        Sex sex,
        Integer heightCm,
        BigDecimal weightKg,
        boolean guardianConsent,
        int age,
        UUID categoryId,
        String categoryName,
        UUID chosenCategoryId,
        UUID organizationId,
        String organizationName,
        UUID personId) {}
