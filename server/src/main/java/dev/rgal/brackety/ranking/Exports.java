package dev.rgal.brackety.ranking;

import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventPermission;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.ranking.dto.ExportPreview;
import dev.rgal.brackety.ranking.dto.ExportRequest;
import dev.rgal.brackety.ranking.dto.ExportSheet;
import java.time.Clock;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * The event's sheets, as the full export writes them or as the club asks (docs/producto/exportaciones.md): the
 * columns it picks, in its order and with its titles, the rows it filters, sorted by what it says, in one file or one
 * per value of a column. The club and whoever has the Participants permission; the personal columns, only with
 * Personal data.
 */
@Service
class Exports {

    static final int PREVIEW_ROWS = 20;
    /** The sheets of the full export, in its order. */
    static final List<String> FULL_EXPORT =
            List.of("participants", "categories", "mats", "groups", "matches", "timeline", "standings", "league");

    static final String CSV = "text/csv;charset=UTF-8";
    static final String ZIP = "application/zip";
    private static final DateTimeFormatter TIME = DateTimeFormatter.ofPattern("HH:mm");

    /**
     * A file to hand over: one CSV, a .zip with one CSV per value of the «Separar por» column, or a workbook with one
     * worksheet per value.
     */
    record Download(String fileName, byte[] body, String contentType) {}

    private final Map<String, Sheet<?>> sheets;
    private final LeagueSheet league;
    private final SheetSource source;
    private final EventAccess access;
    private final DownloadNames names;
    private final ExportTable tables;
    private final EventService events;
    private final Clock clock;
    private final String version;

    Exports(
            List<Sheet<?>> sheets,
            LeagueSheet league,
            SheetSource source,
            EventAccess access,
            DownloadNames names,
            EventService events,
            Clock clock,
            @Value("${brackety.version}") String version) {
        this.sheets = sheets.stream().collect(Collectors.toMap(Sheet::key, Function.identity()));
        this.league = league;
        this.source = source;
        this.access = access;
        this.names = names;
        this.tables = new ExportTable(clock.getZone());
        this.events = events;
        this.clock = clock;
        this.version = version;
    }

    /** In the order of the full export. */
    @Transactional(readOnly = true)
    List<ExportSheet> sheets(UUID eventId, UUID accountId, Locale locale) {
        access.require(eventId, accountId, EventPermission.PARTICIPANTS);
        var personal = access.has(eventId, accountId, EventPermission.PERSONAL_DATA);
        var data = source.load(eventId);
        return FULL_EXPORT.stream()
                .map(sheets::get)
                .map(sheet -> new ExportSheet(
                        sheet.key(),
                        sheet.title(locale),
                        sheet.fields(data).stream()
                                .filter(f -> personal || f.sensitivity() == ExportField.Sensitivity.NORMAL)
                                .map(f -> new ExportSheet.Field(
                                        f.key(),
                                        f.title(locale),
                                        f.kind().name(),
                                        f.sensitivity().name()))
                                .toList()))
                .toList();
    }

    @Transactional(readOnly = true)
    Download export(UUID eventId, UUID accountId, ExportRequest request) {
        var tables = custom(eventId, accountId, request, true);
        var sheet = sheets.get(request.sheet());
        var file = sheet.fileName();
        if ("pdf".equals(request.format())) {
            var title = request.title() == null ? sheet.title(request.headersLocale()) : request.title();
            var pdf = TablePdf.of(tables, title, heading(eventId), footer(), request.landscape());
            return new Download(names.of(eventId, file + ".pdf"), pdf, TablePdf.CONTENT_TYPE);
        }
        if ("xlsx".equals(request.format())) {
            return new Download(names.of(eventId, file + ".xlsx"), Xlsx.of(tables), Xlsx.CONTENT_TYPE);
        }
        if (request.splitBy() == null) {
            var table = tables.getFirst();
            return new Download(names.of(eventId, table.fileName()), Zip.text(table.csv()), CSV);
        }
        var files = new LinkedHashMap<String, byte[]>();
        tables.forEach(table -> files.put(names.of(eventId, table.fileName()), Zip.text(table.csv())));
        return new Download(names.of(eventId, file + ".zip"), Zip.of(files), ZIP);
    }

    private String heading(UUID eventId) {
        var event = events.get(eventId);
        return event.getName() + " · " + SheetText.date(event.getEventDate());
    }

    private String footer() {
        var now = LocalDateTime.now(clock);
        return "Generado el " + SheetText.date(now.toLocalDate()) + " a las " + TIME.format(now) + " · Brackety "
                + version;
    }

    /** The rows of the whole export, without splitting it. */
    @Transactional(readOnly = true)
    ExportPreview preview(UUID eventId, UUID accountId, ExportRequest request) {
        var table = custom(eventId, accountId, request, false).getFirst();
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

    private List<ExportTable.Table> custom(UUID eventId, UUID accountId, ExportRequest request, boolean split) {
        access.require(eventId, accountId, EventPermission.PARTICIPANTS);
        var sheet = sheets.get(request.sheet());
        if (sheet == null) {
            throw EventException.invalid("EXPORT_UNKNOWN_SHEET", "There is no sheet " + request.sheet() + ".");
        }
        var spec = new ExportTable.Spec(
                sheet.fileName(),
                request.columns(),
                request.titlesOrEmpty(),
                request.filtersOrEmpty(),
                request.sortOrEmpty(),
                split ? request.splitBy() : null,
                request.headersLocale(),
                access.has(eventId, accountId, EventPermission.PERSONAL_DATA),
                request.publish());
        return tables(sheet, source.load(eventId), spec);
    }

    private <R> List<ExportTable.Table> tables(Sheet<R> sheet, SheetData data, ExportTable.Spec spec) {
        return tables.of(sheet, data, sheet.rows(data), spec);
    }

    /** A sheet of the full export: its built-in columns in their order, Spanish titles, its own row order. */
    @Transactional(readOnly = true)
    ExportTable.Table builtIn(UUID eventId, UUID accountId, String key) {
        access.require(eventId, accountId, EventRole.CLUB);
        return builtIn(sheets.get(key), source.load(eventId));
    }

    private <R> ExportTable.Table builtIn(Sheet<R> sheet, SheetData data) {
        var rows = sheet.rows(data);
        return tables.of(
                        sheet, data, rows, ExportTable.Spec.builtIn(sheet.fileName(), sheet.builtInColumns(data, rows)))
                .getFirst();
    }

    /** The league standings split by category (its .zip and the full export's folder): each file's name and CSV. */
    @Transactional(readOnly = true)
    Map<String, String> leagueByCategory(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        var data = source.load(eventId);
        var spec = new ExportTable.Spec(
                "clasificacion",
                league.byCategoryColumns(data),
                LeagueSheet.BY_CATEGORY_TITLES,
                List.of(),
                List.of(),
                "category",
                ExportTable.SPANISH,
                true,
                false);
        var files = new LinkedHashMap<String, String>();
        tables(league, data, spec).forEach(table -> files.put(table.fileName(), table.csv()));
        return files;
    }
}
