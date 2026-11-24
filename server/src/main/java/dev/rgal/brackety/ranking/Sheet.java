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

    List<ExportField<R>> fields();

    List<R> rows(SheetData data);

    default String title(Locale locale) {
        return locale.getLanguage().equals("en") ? en() : es();
    }
}
