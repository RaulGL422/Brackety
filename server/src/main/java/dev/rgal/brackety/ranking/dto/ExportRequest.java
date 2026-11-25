package dev.rgal.brackety.ranking.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * A custom export (docs/producto/exportaciones.md): which sheet, which of its columns in which order (with a title of
 * its own if wanted), which rows ({@code filters}: all of them must match), how they sort ({@code sort}: by priority;
 * empty, the sheet's own order), one file per value of a column ({@code splitBy}: CSVs in a .zip, or worksheets of
 * one workbook), the language of the headers (es by default) and the format ({@code csv} by default, or
 * {@code xlsx} or {@code pdf}). A PDF takes a {@code title} (the sheet's by default) and goes {@code landscape} when
 * asked, or by itself when it has many columns. {@code forPublishing}: see {@link #publish()}.
 */
public record ExportRequest(
        @NotBlank @Size(max = 40) String sheet,
        @NotEmpty @Size(max = 60) List<@NotBlank @Size(max = 40) String> columns,
        @Size(max = 60) Map<@NotBlank @Size(max = 40) String, @NotBlank @Size(max = 80) String> titles,
        @Size(max = 10) List<@Valid Filter> filters,
        @Size(max = 5) List<@Valid SortKey> sort,
        @Size(max = 40) String splitBy,
        @Pattern(regexp = "es|en") String locale,
        @Pattern(regexp = "csv|xlsx|pdf") String format,
        @Size(max = 120) String title,
        Boolean landscape,
        Boolean forPublishing) {

    public record SortKey(@NotBlank @Size(max = 40) String column, boolean descending) {}

    /**
     * Rows whose cell, as the file writes it, is one of {@code anyOf} (an empty text: the empty cells), and whose
     * number is between {@code min} and {@code max}, both included (only for number columns).
     */
    public record Filter(
            @NotBlank @Size(max = 40) String column,
            @Size(max = 200) List<@NotNull @Size(max = 200) String> anyOf,
            BigDecimal min,
            BigDecimal max) {}

    public Map<String, String> titlesOrEmpty() {
        return titles == null ? Map.of() : titles;
    }

    public List<Filter> filtersOrEmpty() {
        return filters == null ? List.of() : filters;
    }

    public List<SortKey> sortOrEmpty() {
        return sort == null ? List.of() : sort;
    }

    /** «Para publicar»: first name and the initial of the last name, no personal columns. */
    public boolean publish() {
        return Boolean.TRUE.equals(forPublishing);
    }

    public Locale headersLocale() {
        return Locale.forLanguageTag(locale == null ? "es" : locale);
    }
}
