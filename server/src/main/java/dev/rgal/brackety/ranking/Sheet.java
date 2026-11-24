package dev.rgal.brackety.ranking;

import java.util.List;
import java.util.Locale;

/**
 * A set of rows the club can download (docs/producto/exportaciones.md): one sheet of the full export, or the base of
 * a custom export. Its fields are declared once, in the order of the built-in sheet; its rows come in their natural
 * order.
 */
interface Sheet<R> {

    /** The key the API uses ({@code participants}, {@code matches}…). */
    String key();

    /** The name of its file in the full export, without the extension. */
    String fileName();

    String es();

    String en();

    /** Most sheets offer the same fields in every event; the league's has some for each of its phases. */
    List<ExportField<R>> fields(SheetData data);

    List<R> rows(SheetData data);

    /** The columns of the sheet in the full export: all of them, unless the sheet leaves out what the event lacks. */
    default List<String> builtInColumns(SheetData data, List<R> rows) {
        return fields(data).stream().map(ExportField::key).toList();
    }

    default String title(Locale locale) {
        return locale.getLanguage().equals("en") ? en() : es();
    }
}
