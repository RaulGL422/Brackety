package dev.rgal.brackety.participant.importing.dto;

import java.util.List;
import java.util.UUID;

/**
 * A row with what the server makes of it. {@code categoryId}/{@code categoryName}: where they
 * would compete. With a category mismatch, {@code indicatedCategoryId} (written in the list) and
 * {@code ageCategoryId} (by age) are the two choices offered to the club.
 */
public record CheckedRow(
        ImportRow row,
        Integer age,
        UUID categoryId,
        String categoryName,
        UUID indicatedCategoryId,
        String indicatedCategoryName,
        UUID ageCategoryId,
        String ageCategoryName,
        List<RowIssue> errors,
        List<RowIssue> warnings) {

    public boolean isValid() {
        return errors.isEmpty();
    }
}
