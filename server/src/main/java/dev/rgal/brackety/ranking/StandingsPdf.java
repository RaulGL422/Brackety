package dev.rgal.brackety.ranking;

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
import org.openpdf.text.Font;
import org.openpdf.text.FontFactory;
import org.openpdf.text.PageSize;
import org.openpdf.text.Paragraph;
import org.openpdf.text.Phrase;
import org.openpdf.text.pdf.BaseFont;
import org.openpdf.text.pdf.PdfPCell;
import org.openpdf.text.pdf.PdfPTable;
import org.openpdf.text.pdf.PdfPageEventHelper;
import org.openpdf.text.pdf.PdfTemplate;
import org.openpdf.text.pdf.PdfWriter;

/**
 * The league standings to print or hang in the hall: each category on its own page, with the same columns as its CSV
 * (no birth dates or other data of the students). More than three phases turn the page to landscape.
 */
final class StandingsPdf {

    private static final Font TITLE = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16);
    private static final Font SUBTITLE = FontFactory.getFont(FontFactory.HELVETICA, 10, Font.NORMAL, Color.DARK_GRAY);
    private static final Font HEAD = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 9, Font.NORMAL, Color.WHITE);
    private static final Font CELL = FontFactory.getFont(FontFactory.HELVETICA, 9);
    private static final Font CELL_BOLD = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 9);
    private static final Color HEAD_FILL = new Color(0x33, 0x3D, 0x4A);
    private static final Color STRIPE = new Color(0xF4, 0xF5, 0xF7);
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
        writer.setPageEvent(new Footer(generated));
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
            var cell = cell(header.get(i), HEAD, i == 2 || i == 3 ? Element.ALIGN_LEFT : Element.ALIGN_CENTER);
            cell.setBackgroundColor(HEAD_FILL);
            table.addCell(cell);
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

    private static PdfPCell center(String text, Font font) {
        return cell(text, font, Element.ALIGN_CENTER);
    }

    private static PdfPCell cell(String text, Font font, int align) {
        var cell = new PdfPCell(new Phrase(text, font));
        cell.setHorizontalAlignment(align);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        cell.setPadding(4);
        cell.setBorderColor(new Color(0xD0, 0xD4, 0xDA));
        return cell;
    }

    private static float[] toArray(List<Float> values) {
        var array = new float[values.size()];
        for (var i = 0; i < array.length; i++) {
            array[i] = values.get(i);
        }
        return array;
    }

    /** "Página X de Y": Y is only known at the end, so it goes in a template filled when the document closes. */
    private static final class Footer extends PdfPageEventHelper {

        private final String generated;
        private final BaseFont font;
        private PdfTemplate total;

        Footer(String generated) {
            this.generated = generated;
            this.font = FontFactory.getFont(FontFactory.HELVETICA).getBaseFont();
        }

        @Override
        public void onOpenDocument(PdfWriter writer, Document document) {
            total = writer.getDirectContent().createTemplate(30, 12);
        }

        @Override
        public void onEndPage(PdfWriter writer, Document document) {
            var canvas = writer.getDirectContent();
            var y = document.bottom() - 24;
            var page = "Página " + writer.getPageNumber() + " de ";
            canvas.beginText();
            canvas.setFontAndSize(font, 8);
            canvas.setColorFill(Color.DARK_GRAY);
            canvas.showTextAligned(Element.ALIGN_LEFT, "Generado el " + generated, document.left(), y, 0);
            var x = document.right() - 30 - font.getWidthPoint(page, 8);
            canvas.showTextAligned(Element.ALIGN_LEFT, page, x, y, 0);
            canvas.endText();
            canvas.addTemplate(total, document.right() - 30, y);
        }

        @Override
        public void onCloseDocument(PdfWriter writer, Document document) {
            total.beginText();
            total.setFontAndSize(font, 8);
            total.setColorFill(Color.DARK_GRAY);
            // On close the writer already counts the next, empty page.
            total.showText(String.valueOf(writer.getPageNumber() - 1));
            total.endText();
        }
    }
}
