package dev.rgal.brackety.ranking;

import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.ranking.dto.ExportPreview;
import dev.rgal.brackety.ranking.dto.ExportRequest;
import dev.rgal.brackety.ranking.dto.ExportRequest.SortKey;
import dev.rgal.brackety.ranking.dto.ExportSheet;
import java.math.BigDecimal;
import java.text.Collator;
import java.time.Clock;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * The event's sheets, as the full export writes them or as the club asks (docs/producto/exportaciones.md): the
 * columns it picks, in its order, with the rows sorted by what it says. Only the club of the event.
 */
@Service
class Exports {

    static final int PREVIEW_ROWS = 20;
    /** The sheets of the full export, in its order. */
    static final List<String> FULL_EXPORT =
            List.of("participants", "categories", "mats", "groups", "matches", "timeline");

    private static final Collator TEXT = Collator.getInstance(Locale.forLanguageTag("es"));

    /** The table to write: titles and cells as they go in the file. */
    record Table(String fileName, List<String> headers, List<List<Object>> rows) {

        String csv() {
            return Csv.of(headers, rows);
        }
    }

    private final Map<String, Sheet<?>> sheets;
    private final SheetSource source;
    private final EventAccess access;
    private final ZoneId zone;

    Exports(List<Sheet<?>> sheets, SheetSource source, EventAccess access, Clock clock) {
        this.sheets = sheets.stream().collect(Collectors.toMap(Sheet::key, Function.identity()));
        this.source = source;
        this.access = access;
        this.zone = clock.getZone();
    }

    /** In the order of the full export. */
    @Transactional(readOnly = true)
    List<ExportSheet> sheets(UUID eventId, UUID accountId, Locale locale) {
        access.require(eventId, accountId, EventRole.CLUB);
        return FULL_EXPORT.stream()
                .map(sheets::get)
                .map(sheet -> new ExportSheet(
                        sheet.key(),
                        sheet.title(locale),
                        sheet.fields().stream()
                                .map(f -> new ExportSheet.Field(
                                        f.key(),
                                        f.title(locale),
                                        f.kind().name(),
                                        f.sensitivity().name()))
                                .toList()))
                .toList();
    }

    @Transactional(readOnly = true)
    Table export(UUID eventId, UUID accountId, ExportRequest request) {
        access.require(eventId, accountId, EventRole.CLUB);
        var sheet = sheets.get(request.sheet());
        if (sheet == null) {
            throw EventException.invalid("EXPORT_UNKNOWN_SHEET", "There is no sheet " + request.sheet() + ".");
        }
        return table(sheet, source.load(eventId), request.columns(), request.sortOrEmpty(), request.headersLocale());
    }

    @Transactional(readOnly = true)
    ExportPreview preview(UUID eventId, UUID accountId, ExportRequest request) {
        var table = export(eventId, accountId, request);
        return new ExportPreview(
                table.headers(),
                table.rows().stream()
                        .limit(PREVIEW_ROWS)
                        .map(row -> row.stream()
                                .map(cell -> cell == null ? null : cell.toString())
                                .toList())
                        .toList(),
                table.rows().size());
    }

    /** A sheet of the full export: every field in its order, Spanish titles, the sheet's own row order. */
    @Transactional(readOnly = true)
    Table builtIn(UUID eventId, UUID accountId, String key) {
        access.require(eventId, accountId, EventRole.CLUB);
        var sheet = sheets.get(key);
        var columns = sheet.fields().stream().map(ExportField::key).toList();
        return table(sheet, source.load(eventId), columns, List.of(), Locale.forLanguageTag("es"));
    }

    private <R> Table table(Sheet<R> sheet, SheetData data, List<String> columns, List<SortKey> sort, Locale locale) {
        var byKey = sheet.fields().stream().collect(Collectors.toMap(ExportField::key, Function.identity()));
        if (new HashSet<>(columns).size() != columns.size()) {
            throw EventException.invalid("EXPORT_REPEATED_COLUMN", "A column is chosen twice.");
        }
        var chosen = columns.stream().map(key -> field(byKey, key)).toList();
        var rows = new ArrayList<>(sheet.rows(data));
        if (!sort.isEmpty()) {
            rows.sort(sort.stream()
                    .map(key -> order(field(byKey, key.column()), key.descending()))
                    .reduce(Comparator::thenComparing)
                    .orElseThrow());
        }
        return new Table(
                sheet.fileName() + ".csv",
                chosen.stream().map(f -> f.title(locale)).toList(),
                rows.stream()
                        .map(row -> chosen.stream()
                                .map(f -> f.write(f.read(row), zone))
                                .toList())
                        .toList());
    }

    private static <R> ExportField<R> field(Map<String, ExportField<R>> byKey, String key) {
        var field = byKey.get(key);
        if (field == null) {
            throw EventException.invalid("EXPORT_UNKNOWN_COLUMN", "This sheet has no column " + key + ".");
        }
        return field;
    }

    // Empty cells last either way.
    private static <R> Comparator<R> order(ExportField<R> field, boolean descending) {
        Comparator<Object> values = Exports::compare;
        return Comparator.comparing(field::read, Comparator.nullsLast(descending ? values.reversed() : values));
    }

    @SuppressWarnings({"unchecked", "rawtypes"})
    private static int compare(Object a, Object b) {
        if (a instanceof Number x && b instanceof Number y) {
            return new BigDecimal(x.toString()).compareTo(new BigDecimal(y.toString()));
        }
        if (a instanceof Comparable x && !(a instanceof String) && a.getClass() == b.getClass()) {
            return x.compareTo(b);
        }
        return TEXT.compare(Objects.toString(a), Objects.toString(b));
    }
}
