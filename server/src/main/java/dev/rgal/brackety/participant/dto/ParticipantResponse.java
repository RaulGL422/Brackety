package dev.rgal.brackety.participant.dto;

import java.time.LocalDate;
import java.util.UUID;

/** {@code categoryId} is null when no category of the event covers the age. */
public record ParticipantResponse(
        UUID id,
        String firstName,
        String lastName,
        LocalDate birthDate,
        Integer heightCm,
        boolean guardianConsent,
        int age,
        UUID categoryId,
        String categoryName) {}
