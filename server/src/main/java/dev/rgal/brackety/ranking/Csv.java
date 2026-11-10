package dev.rgal.brackety.ranking;

import java.util.List;
import java.util.stream.Collectors;

/** CSV for spreadsheets set to Spanish: ';' separator and a BOM so accents open right. */
final class Csv {

    static final String BOM = "﻿";

    private Csv() {}

    static String of(List<String> header, List<? extends List<?>> rows) {
        var out = new StringBuilder(BOM).append(line(header));
        rows.forEach(row -> out.append(line(row)));
        return out.toString();
    }

    private static String line(List<?> cells) {
        return cells.stream().map(Csv::cell).collect(Collectors.joining(";")) + "\r\n";
    }

    private static String cell(Object value) {
        if (value == null) {
            return "";
        }
        var text = value.toString();
        // A leading = + - @ would run as a formula when the file is opened (CSV injection); a leading tab or
        // carriage return can hide one from a spreadsheet that skips them.
        if (!text.isEmpty() && "=+-@\t\r".indexOf(text.charAt(0)) >= 0 && !(value instanceof Number)) {
            text = "'" + text;
        }
        if (text.contains(";") || text.contains("\"") || text.contains("\n") || text.contains("\r")) {
            text = "\"" + text.replace("\"", "\"\"") + "\"";
        }
        return text;
    }
}
