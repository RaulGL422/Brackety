package dev.rgal.brackety.ranking;

import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.eventpackage.EventPackageService;
import dev.rgal.brackety.ranking.ExportField.Kind;
import dev.rgal.brackety.ranking.ExportField.Sensitivity;
import dev.rgal.brackety.ranking.dto.ExportRequest.Filter;
import dev.rgal.brackety.ranking.dto.ExportRequest.SortKey;
import java.math.BigDecimal;
import java.text.Collator;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;
import java.util.function.Predicate;
import java.util.stream.Collectors;

/**
 * One sheet as a table (docs/producto/exportaciones.md): the chosen columns with their titles, the rows that pass the
 * filters, sorted, and split in one table per value of a column when asked.
 */
final class ExportTable {

    static final Locale SPANISH = Locale.forLanguageTag("es");
    private static final Collator TEXT = Collator.getInstance(SPANISH);

    /**
     * A table to write: its CSV file, its name as a worksheet, the titles, the kind of each column and the real
     * values. The CSV writes them as text ({@link #rows}); Excel, numbers and dates as such ({@link Xlsx}).
     */
    record Table(
            String fileName,
            String name,
            List<String> headers,
            List<Kind> kinds,
            List<List<Object>> values,
            ZoneId zone) {

        /** The cells as the CSV writes them. */
        List<List<Object>> rows() {
            return values.stream()
                    .map(row -> {
                        var cells = new ArrayList<Object>(row.size());
                        for (int i = 0; i < row.size(); i++) {
                            cells.add(ExportField.write(kinds.get(i), row.get(i), zone));
                        }
                        return (List<Object>) cells;
                    })
                    .toList();
        }

        String csv() {
            return Csv.of(headers, rows());
        }
    }

    /**
     * What to write of a sheet; {@code file}: the name of its files, without the extension. Without
     * {@code personalData} (the permission) or when {@code publish}ing, the personal and minors' columns are not
     * there; publishing also shortens the names ({@link PublicNames}).
     */
    record Spec(
            String file,
            List<String> columns,
            Map<String, String> titles,
            List<Filter> filters,
            List<SortKey> sort,
            String splitBy,
            Locale locale,
            boolean personalData,
            boolean publish) {

        static Spec builtIn(String file, List<String> columns) {
            return new Spec(file, columns, Map.of(), List.of(), List.of(), null, SPANISH, true, false);
        }
    }

    private final ZoneId zone;

    ExportTable(ZoneId zone) {
        this.zone = zone;
    }

    <R> List<Table> of(Sheet<R> sheet, SheetData data, List<R> sheetRows, Spec spec) {
        var names = spec.publish() ? new PublicNames(data.participants()) : null;
        var byKey = sheet.fields(data).stream()
                .filter(f -> f.sensitivity() == Sensitivity.NORMAL || (spec.personalData() && !spec.publish()))
                .map(f -> names == null ? f : f.mapped(value -> names.apply(f.key(), value)))
                .collect(Collectors.toMap(ExportField::key, Function.identity()));
        if (new HashSet<>(spec.columns()).size() != spec.columns().size()) {
            throw EventException.invalid("EXPORT_REPEATED_COLUMN", "A column is chosen twice.");
        }
        var chosen = spec.columns().stream().map(key -> field(byKey, key)).toList();
        spec.titles().keySet().stream()
                .filter(key -> !spec.columns().contains(key))
                .findFirst()
                .ifPresent(key -> {
                    throw EventException.invalid("EXPORT_UNKNOWN_COLUMN", "A title for a column not chosen: " + key);
                });
        var headers = chosen.stream()
                .map(f -> spec.titles().getOrDefault(f.key(), f.title(spec.locale())))
                .toList();
        Predicate<R> keep = row -> true;
        for (var filter : spec.filters()) {
            keep = keep.and(matches(filter, byKey));
        }
        var rows = new ArrayList<>(sheetRows.stream().filter(keep).toList());
        if (!spec.sort().isEmpty()) {
            rows.sort(spec.sort().stream()
                    .map(key -> order(field(byKey, key.column()), key.descending()))
                    .reduce(Comparator::thenComparing)
                    .orElseThrow());
        }
        var kinds = chosen.stream().map(ExportField::kind).toList();
        if (spec.splitBy() == null) {
            return List.of(new Table(
                    spec.file() + ".csv", sheet.title(spec.locale()), headers, kinds, values(chosen, rows), zone));
        }
        var split = field(byKey, spec.splitBy());
        var parts = new LinkedHashMap<String, List<R>>();
        rows.forEach(row -> parts.computeIfAbsent(text(split, row), value -> new ArrayList<>())
                .add(row));
        var used = new HashSet<String>();
        return parts.entrySet().stream()
                .map(part -> new Table(
                        fileFor(spec.file(), part.getKey(), used),
                        part.getKey().isEmpty() ? "Sin valor" : part.getKey(),
                        headers,
                        kinds,
                        values(chosen, part.getValue()),
                        zone))
                .toList();
    }

    // "clasificacion_9-10.csv"; two values that write the same (9-10, 9 10) get -2, -3… so no file replaces another.
    private static String fileFor(String file, String value, Set<String> used) {
        var base = file + "_" + (value.isEmpty() ? "sin-valor" : EventPackageService.slug(value));
        var name = base;
        for (int n = 2; !used.add(name); n++) {
            name = base + "-" + n;
        }
        return name + ".csv";
    }

    private static <R> List<List<Object>> values(List<ExportField<R>> chosen, List<R> rows) {
        return rows.stream()
                .map(row -> chosen.stream().map(f -> (Object) f.read(row)).toList())
                .toList();
    }

    /** The cell as the file writes it; empty, "". */
    private <R> String text(ExportField<R> field, R row) {
        var cell = field.write(field.read(row), zone);
        return cell == null ? "" : cell.toString();
    }

    private <R> Predicate<R> matches(Filter filter, Map<String, ExportField<R>> byKey) {
        var field = field(byKey, filter.column());
        var range = filter.min() != null || filter.max() != null;
        if (range && field.kind() != Kind.NUMBER && field.kind() != Kind.DECIMAL) {
            throw EventException.invalid(
                    "EXPORT_FILTER_NOT_A_NUMBER",
                    "Only a number column takes a minimum or a maximum: " + filter.column() + ".");
        }
        var anyOf = filter.anyOf() == null ? List.<String>of() : filter.anyOf();
        return row -> {
            var text = text(field, row);
            if (!anyOf.isEmpty() && anyOf.stream().noneMatch(text::equalsIgnoreCase)) {
                return false;
            }
            if (!range) {
                return true;
            }
            if (!(field.read(row) instanceof Number number)) {
                return false;
            }
            var value = new BigDecimal(number.toString());
            return (filter.min() == null || value.compareTo(filter.min()) >= 0)
                    && (filter.max() == null || value.compareTo(filter.max()) <= 0);
        };
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
        Comparator<Object> values = ExportTable::compare;
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
