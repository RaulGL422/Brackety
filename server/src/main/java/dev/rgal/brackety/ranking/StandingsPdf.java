package dev.rgal.brackety.ranking;

import static dev.rgal.brackety.ranking.PdfStyle.CELL;
import static dev.rgal.brackety.ranking.PdfStyle.CELL_BOLD;
import static dev.rgal.brackety.ranking.PdfStyle.STRIPE;
import static dev.rgal.brackety.ranking.PdfStyle.SUBTITLE;
import static dev.rgal.brackety.ranking.PdfStyle.TITLE;
import static dev.rgal.brackety.ranking.PdfStyle.cell;
import static dev.rgal.brackety.ranking.PdfStyle.center;
import static dev.rgal.brackety.ranking.PdfStyle.head;
import static dev.rgal.brackety.ranking.PdfStyle.toArray;

import dev.rgal.brackety.ranking.dto.LeagueStandings;
import dev.rgal.brackety.ranking.dto.LeagueStandings.Row;
import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.stream.Collectors;
import org.openpdf.text.Document;
import org.openpdf.text.Element;
import org.openpdf.text.PageSize;
import org.openpdf.text.Paragraph;
import org.openpdf.text.pdf.PdfPCell;
import org.openpdf.text.pdf.PdfPTable;
import org.openpdf.text.pdf.PdfWriter;

/**
 * The league standings to print or hang in the hall: each category on its own page, with the same columns as its CSV
 * (no birth dates or other data of the students). More than three phases turn the page to landscape.
 */
final class StandingsPdf {

    private static final Color[] MEDAL_FILL = {
        new Color(0xF7, 0xE7, 0xA6), new Color(0xE2, 0xE5, 0xE9), new Color(0xF2, 0xD3, 0xB3)
    };

    private StandingsPdf() {}

    /** {@code heading}: league, phase and date; {@code generated}: when, for the footer. */
    static byte[] of(LeagueStandings standings, String heading, String generated) {
        var landscape = standings.phases().size() > 3;
        var document = new Document(landscape ? PageSize.A4.rotate() : PageSize.A4, 36, 36, 36, 48);
        var out = new ByteArrayOutputStream();
        var writer = PdfWriter.getInstance(document, out);
        writer.setPageEvent(new PdfStyle.Footer("Generado el " + generated));
        document.addTitle("Clasificación por categoría");
        document.open();
        var byCategory = standings.rows().stream()
                .collect(Collectors.groupingBy(Row::categoryName, LinkedHashMap::new, Collectors.toList()));
        if (byCategory.isEmpty()) {
            document.add(new Paragraph(heading, TITLE));
            document.add(new Paragraph("Todavía no hay nadie en la clasificación.", SUBTITLE));
        }
        var first = true;
        for (var category : byCategory.entrySet()) {
            if (!first) {
                document.newPage();
            }
            first = false;
            document.add(new Paragraph(category.getKey(), TITLE));
            var subtitle = new Paragraph(heading, SUBTITLE);
            subtitle.setSpacingAfter(10);
            document.add(subtitle);
            document.add(table(standings.phases(), category.getValue()));
        }
        document.close();
        return out.toByteArray();
    }

    private static PdfPTable table(List<LeagueStandings.Phase> phases, List<Row> rows) {
        var header = new ArrayList<>(List.of("Pos.", "Medalla", "Nombre", "Club"));
        var widths = new ArrayList<>(List.of(5f, 12f, 26f, 21f));
        phases.forEach(p -> {
            header.add("Fase " + p.number());
            widths.add(7f);
        });
        header.addAll(List.of("Total", "Adv."));
        widths.addAll(List.of(7f, 6f));
        var table = new PdfPTable(header.size());
        table.setWidthPercentage(100);
        table.setWidths(toArray(widths));
        table.setHeaderRows(1);
        for (var i = 0; i < header.size(); i++) {
            table.addCell(head(header.get(i), i == 2 || i == 3 ? Element.ALIGN_LEFT : Element.ALIGN_CENTER));
        }
        for (var i = 0; i < rows.size(); i++) {
            var r = rows.get(i);
            var fill = r.medal() != null ? MEDAL_FILL[r.medal() - 1] : i % 2 == 1 ? STRIPE : Color.WHITE;
            var cells = new ArrayList<PdfPCell>();
            // With 0 points nobody has a place yet (the app and the CSV show a dash too).
            cells.add(center(r.total() > 0 ? String.valueOf(r.position()) : "–", CELL_BOLD));
            cells.add(center(r.medal() == null ? "" : SheetText.medal(r.medal()), CELL));
            cells.add(cell(r.firstName() + " " + r.lastName(), CELL, Element.ALIGN_LEFT));
            cells.add(cell(r.organizationName() == null ? "" : r.organizationName(), CELL, Element.ALIGN_LEFT));
            r.phases().forEach(p -> cells.add(center(p == null ? "–" : String.valueOf(p.total()), CELL)));
            cells.add(center(String.valueOf(r.total()), CELL_BOLD));
            cells.add(center(String.valueOf(r.warnings()), CELL));
            cells.forEach(c -> {
                c.setBackgroundColor(fill);
                table.addCell(c);
            });
        }
        return table;
    }
}
