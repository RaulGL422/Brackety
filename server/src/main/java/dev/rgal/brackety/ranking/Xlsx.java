package dev.rgal.brackety.ranking;

import dev.rgal.brackety.ranking.ExportField.Kind;
import dev.rgal.brackety.ranking.ExportTable.Table;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import org.dhatim.fastexcel.Workbook;
import org.dhatim.fastexcel.Worksheet;

/**
 * Excel workbooks (docs/producto/exportaciones.md): one worksheet per table, the titles in bold and frozen, numbers
 * and dates as such so Excel sorts and adds them. A text is always a text, never a formula.
 */
final class Xlsx {

    static final String CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
    // Excel refuses these in a worksheet's name, and names longer than 31 characters.
    private static final String NOT_IN_NAMES = "[\\[\\]:*?/\\\\']";
    private static final int NAME_LENGTH = 28;

    private Xlsx() {}

    static byte[] of(List<Table> tables) {
        var out = new ByteArrayOutputStream();
        try {
            var book = new Workbook(out, "Brackety", "1.0");
            var used = new HashSet<String>();
            for (var table : tables) {
                write(book.newWorksheet(sheetName(table.name(), used)), table);
            }
            book.finish();
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        return out.toByteArray();
    }

    private static void write(Worksheet sheet, Table table) {
        for (int c = 0; c < table.headers().size(); c++) {
            sheet.value(0, c, table.headers().get(c));
            sheet.style(0, c).bold().set();
        }
        sheet.freezePane(0, 1);
        for (int r = 0; r < table.values().size(); r++) {
            var row = table.values().get(r);
            for (int c = 0; c < row.size(); c++) {
                cell(sheet, r + 1, c, table.kinds().get(c), row.get(c), table.zone());
            }
        }
    }

    private static void cell(Worksheet sheet, int r, int c, Kind kind, Object raw, ZoneId zone) {
        if (raw == null) {
            return;
        }
        switch (kind) {
            case DATE -> {
                sheet.value(r, c, raw instanceof LocalDate date ? date : LocalDate.ofInstant((Instant) raw, zone));
                sheet.style(r, c).format("dd/mm/yyyy").set();
            }
            case DATE_TIME -> {
                sheet.value(r, c, LocalDateTime.ofInstant((Instant) raw, zone));
                sheet.style(r, c).format("dd/mm/yyyy hh:mm:ss").set();
            }
            default -> {
                var written = kind == Kind.DECIMAL ? raw : ExportField.write(kind, raw, zone);
                if (written instanceof Number number) {
                    sheet.value(r, c, number);
                } else {
                    sheet.value(r, c, String.valueOf(written));
                }
            }
        }
    }

    // Unique without minding case, as Excel compares them.
    private static String sheetName(String name, Set<String> used) {
        var base = name.replaceAll(NOT_IN_NAMES, "-").strip();
        if (base.isEmpty()) {
            base = "Hoja";
        }
        if (base.length() > NAME_LENGTH) {
            base = base.substring(0, NAME_LENGTH).strip();
        }
        var candidate = base;
        for (int n = 2; !used.add(candidate.toLowerCase(Locale.ROOT)); n++) {
            candidate = base + " " + n;
        }
        return candidate;
    }
}
