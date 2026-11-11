package dev.rgal.brackety.participant.dto;

import java.time.LocalDate;
import java.util.UUID;

/**
 * {@code categoryId}: the category they compete in, null when none covers their age.
 * {@code chosenCategoryId}: set when it was chosen instead of following the age.
 * {@code personId}: the same person in every phase of the league.
 */
public record ParticipantResponse(
        UUID id,
        String firstName,
        String lastName,
        LocalDate birthDate,
        Integer heightCm,
        boolean guardianConsent,
        int age,
        UUID categoryId,
        String categoryName,
        UUID chosenCategoryId,
        UUID organizationId,
        String organizationName,
        UUID personId) {}
