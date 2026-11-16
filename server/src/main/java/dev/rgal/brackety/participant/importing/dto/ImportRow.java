package dev.rgal.brackety.participant.importing.dto;

import dev.rgal.brackety.participant.Sex;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * One participant of an imported list, as read and then edited by the club. Nothing here is
 * trusted: the server checks every row.
 *
 * @param birthDateText the date as written, kept when it could not be read as a real date
 * @param categoryText the category as written in the list, or null
 * @param categoryId a category the club chose for them, or null to follow the age
 * @param sex required to register them; the list may not say it
 * @param unsure fields that could not be read with certainty
 */
public record ImportRow(
        @Size(max = 200) String firstName,
        @Size(max = 200) String lastName,
        LocalDate birthDate,
        @Size(max = 40) String birthDateText,
        Sex sex,
        Integer heightCm,
        BigDecimal weightKg,
        @Size(max = 40) String categoryText,
        UUID categoryId,
        @Size(max = 5) List<String> unsure) {

    public ImportRow {
        unsure = unsure == null ? List.of() : List.copyOf(unsure);
    }
}
