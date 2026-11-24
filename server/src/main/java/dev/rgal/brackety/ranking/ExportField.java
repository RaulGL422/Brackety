package dev.rgal.brackety.ranking;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Locale;
import java.util.function.Function;

/**
 * A column a sheet offers (docs/producto/exportaciones.md): its key, its title in Spanish and English, the kind of
 * value it holds, how sensitive it is and how a row gives it. The value is the real one (a date, a number), so rows
 * sort by it; {@link #write} turns it into the text of the sheet.
 */
record ExportField<R>(String key, String es, String en, Kind kind, Sensitivity sensitivity, Function<R, ?> value) {

    enum Kind {
        TEXT,
        NUMBER,
        /** With a decimal comma. */
        DECIMAL,
        /** A LocalDate, or an Instant on the event's clock. */
        DATE,
        TIME,
        DATE_TIME,
        /** Milliseconds, as m:ss. */
        DURATION
    }

    /** docs/06-legal-rgpd.md: personal data (birth date, measures) and data about minors (the guardian's consent). */
    enum Sensitivity {
        NORMAL,
        PERSONAL,
        MINORS
    }

    static <R> ExportField<R> of(String key, String es, String en, Kind kind, Function<R, ?> value) {
        return new ExportField<>(key, es, en, kind, Sensitivity.NORMAL, value);
    }

    static <R> ExportField<R> text(String key, String es, String en, Function<R, ?> value) {
        return of(key, es, en, Kind.TEXT, value);
    }

    static <R> ExportField<R> number(String key, String es, String en, Function<R, ?> value) {
        return of(key, es, en, Kind.NUMBER, value);
    }

    ExportField<R> as(Sensitivity level) {
        return new ExportField<>(key, es, en, kind, level, value);
    }

    String title(Locale locale) {
        return locale.getLanguage().equals("en") ? en : es;
    }

    Object read(R row) {
        return value.apply(row);
    }

    /** The cell as the sheet writes it: dd/mm/aaaa dates, HH:mm:ss times, m:ss durations, decimal commas. */
    Object write(Object raw, ZoneId zone) {
        if (raw == null) {
            return null;
        }
        return switch (kind) {
            case TEXT, NUMBER -> raw;
            case DECIMAL -> SheetText.decimal((BigDecimal) raw);
            case DATE -> raw instanceof LocalDate date ? SheetText.date(date) : SheetText.date((Instant) raw, zone);
            case TIME -> SheetText.time((Instant) raw, zone);
            case DATE_TIME -> SheetText.date((Instant) raw, zone) + " " + SheetText.time((Instant) raw, zone);
            case DURATION -> SheetText.duration(((Number) raw).longValue());
        };
    }
}
