package dev.rgal.brackety.scoreboard;

import dev.rgal.brackety.event.EventException;
import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * The CSV a device exports with the actions it could not send (docs/modulos/offline.md, "Rescate"). Written by
 * the app (`offline_ops_csv.dart`); ';' separated, quotes as in RFC 4180:
 *
 * <pre>
 * brackety-offline-ops;1
 * opId;matchId;type;side;reason;at;knownEvents;actor
 * </pre>
 */
final class OfflineOpsCsv {

    static final String MAGIC = "brackety-offline-ops";
    static final String VERSION = "1";
    static final List<String> COLUMNS =
            List.of("opId", "matchId", "type", "side", "reason", "at", "knownEvents", "actor");
    static final int MAX_ROWS = 10_000;

    record Row(
            int line,
            UUID opId,
            UUID matchId,
            MatchEventType type,
            Side side,
            String reason,
            Instant at,
            int knownEvents,
            UUID actor) {}

    private OfflineOpsCsv() {}

    static List<Row> parse(String text) {
        var lines = records(text.startsWith("﻿") ? text.substring(1) : text);
        if (lines.size() < 2 || !lines.get(0).equals(List.of(MAGIC, VERSION))) {
            throw EventException.invalid("Not a file of pending actions (version " + VERSION + ").");
        }
        if (!lines.get(1).equals(COLUMNS)) {
            throw EventException.invalid("Unexpected columns: " + String.join(";", lines.get(1)));
        }
        if (lines.size() - 2 > MAX_ROWS) {
            throw EventException.invalid("Too many rows.");
        }
        var rows = new ArrayList<Row>();
        for (int i = 2; i < lines.size(); i++) {
            var cells = lines.get(i);
            if (cells.size() == 1 && cells.get(0).isBlank()) {
                continue;
            }
            rows.add(row(i + 1, cells));
        }
        return rows;
    }

    private static Row row(int line, List<String> cells) {
        if (cells.size() != COLUMNS.size()) {
            throw invalid(line, "expected " + COLUMNS.size() + " columns");
        }
        try {
            return new Row(
                    line,
                    UUID.fromString(cells.get(0)),
                    UUID.fromString(cells.get(1)),
                    MatchEventType.valueOf(cells.get(2)),
                    cells.get(3).isEmpty() ? null : Side.valueOf(cells.get(3)),
                    cells.get(4).isEmpty() ? null : cells.get(4),
                    Instant.parse(cells.get(5)),
                    Integer.parseInt(cells.get(6)),
                    cells.get(7).isEmpty() ? null : UUID.fromString(cells.get(7)));
        } catch (IllegalArgumentException | DateTimeParseException e) {
            throw invalid(line, "a value is not valid");
        }
    }

    private static EventException invalid(int line, String why) {
        return EventException.invalid("Line " + line + ": " + why + ".");
    }

    // Splits into records and cells; a quoted cell may hold ';', quotes ("") and line breaks.
    private static List<List<String>> records(String text) {
        var records = new ArrayList<List<String>>();
        var cells = new ArrayList<String>();
        var cell = new StringBuilder();
        var quoted = false;
        for (int i = 0; i < text.length(); i++) {
            var c = text.charAt(i);
            if (quoted) {
                if (c == '"' && i + 1 < text.length() && text.charAt(i + 1) == '"') {
                    cell.append('"');
                    i++;
                } else if (c == '"') {
                    quoted = false;
                } else {
                    cell.append(c);
                }
            } else if (c == '"') {
                quoted = true;
            } else if (c == ';') {
                cells.add(cell.toString());
                cell.setLength(0);
            } else if (c == '\n' || c == '\r') {
                if (c == '\r' && i + 1 < text.length() && text.charAt(i + 1) == '\n') {
                    i++;
                }
                cells.add(cell.toString());
                cell.setLength(0);
                records.add(cells);
                cells = new ArrayList<>();
            } else {
                cell.append(c);
            }
        }
        if (!cell.isEmpty() || !cells.isEmpty()) {
            cells.add(cell.toString());
            records.add(cells);
        }
        return records;
    }
}
