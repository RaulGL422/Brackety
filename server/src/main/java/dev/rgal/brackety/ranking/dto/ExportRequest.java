package dev.rgal.brackety.ranking.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.Locale;

/**
 * A custom export (docs/producto/exportaciones.md): which sheet, which of its columns in which order, how the rows
 * sort ({@code sort}: by priority; empty, the sheet's own order) and the language of the headers (es by default).
 */
public record ExportRequest(
        @NotBlank @Size(max = 40) String sheet,
        @NotEmpty @Size(max = 60) List<@NotBlank @Size(max = 40) String> columns,
        @Size(max = 5) List<@Valid SortKey> sort,
        @Pattern(regexp = "es|en") String locale) {

    public record SortKey(@NotBlank @Size(max = 40) String column, boolean descending) {}

    public List<SortKey> sortOrEmpty() {
        return sort == null ? List.of() : sort;
    }

    public Locale headersLocale() {
        return Locale.forLanguageTag(locale == null ? "es" : locale);
    }
}
