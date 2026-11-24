package dev.rgal.brackety.ranking.dto;

import java.util.List;

/** A sheet the club can export and its fields, titled in the language asked; the screen is built from these. */
public record ExportSheet(String key, String title, List<Field> fields) {

    /**
     * {@code kind}: TEXT, NUMBER, DECIMAL, DATE, TIME, DATE_TIME or DURATION. {@code sensitivity}: NORMAL,
     * PERSONAL or MINORS (docs/06-legal-rgpd.md).
     */
    public record Field(String key, String title, String kind, String sensitivity) {}
}
