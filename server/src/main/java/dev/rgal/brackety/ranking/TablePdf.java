package dev.rgal.brackety.ranking;

import static dev.rgal.brackety.ranking.PdfStyle.CELL;
import static dev.rgal.brackety.ranking.PdfStyle.STRIPE;
import static dev.rgal.brackety.ranking.PdfStyle.SUBTITLE;
import static dev.rgal.brackety.ranking.PdfStyle.TITLE;
import static dev.rgal.brackety.ranking.PdfStyle.cell;
import static dev.rgal.brackety.ranking.PdfStyle.head;

import dev.rgal.brackety.ranking.ExportField.Kind;
import dev.rgal.brackety.ranking.ExportTable.Table;
import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.util.List;
import java.util.Set;
import org.openpdf.text.Document;
import org.openpdf.text.Element;
import org.openpdf.text.PageSize;
import org.openpdf.text.Paragraph;
import org.openpdf.text.pdf.PdfPTable;
import org.openpdf.text.pdf.PdfWriter;

/**
 * Any sheet to print (docs/producto/exportaciones.md): each table on its own page (one per value when it is split),
 * with its title, the event and the footer. More than {@link #PORTRAIT_COLUMNS} columns turn the page to landscape,
 * unless the club says which.
 */
final class TablePdf {

    static final String CONTENT_TYPE = "application/pdf";
    static final int PORTRAIT_COLUMNS = 6;
    private static final Set<Kind> CENTERED = Set.of(Kind.NUMBER, Kind.DECIMAL, Kind.DATE, Kind.TIME, Kind.DURATION);

    private TablePdf() {}

    /** {@code heading}: the event and its date; {@code footer}: when and with which version it was made. */
    static byte[] of(List<Table> tables, String title, String heading, String footer, Boolean landscape) {
        var columns = tables.isEmpty() ? 0 : tables.getFirst().headers().size();
        var wide = landscape != null ? landscape : columns > PORTRAIT_COLUMNS;
        var document = new Document(wide ? PageSize.A4.rotate() : PageSize.A4, 36, 36, 36, 48);
        var out = new ByteArrayOutputStream();
        PdfWriter.getInstance(document, out).setPageEvent(new PdfStyle.Footer(footer));
        document.addTitle(title);
        document.open();
        if (tables.isEmpty()) {
            document.add(new Paragraph(title, TITLE));
            document.add(new Paragraph("No hay filas que mostrar.", SUBTITLE));
        }
        var first = true;
        for (var table : tables) {
            if (!first) {
                document.newPage();
            }
            first = false;
            // Split, each page is one value: the export's title goes under it with the event.
            var split = tables.size() > 1;
            document.add(new Paragraph(split ? table.name() : title, TITLE));
            var subtitle = new Paragraph(split ? title + " · " + heading : heading, SUBTITLE);
            subtitle.setSpacingAfter(10);
            document.add(subtitle);
            document.add(grid(table));
        }
        document.close();
        return out.toByteArray();
    }

    private static PdfPTable grid(Table table) {
        var grid = new PdfPTable(table.headers().size());
        grid.setWidthPercentage(100);
        grid.setHeaderRows(1);
        for (var c = 0; c < table.headers().size(); c++) {
            grid.addCell(head(table.headers().get(c), align(table.kinds().get(c))));
        }
        var rows = table.rows();
        for (var r = 0; r < rows.size(); r++) {
            var fill = r % 2 == 1 ? STRIPE : Color.WHITE;
            var row = rows.get(r);
            for (var c = 0; c < row.size(); c++) {
                var value = row.get(c);
                var cell = cell(
                        value == null ? "" : value.toString(),
                        CELL,
                        align(table.kinds().get(c)));
                cell.setBackgroundColor(fill);
                grid.addCell(cell);
            }
        }
        return grid;
    }

    private static int align(Kind kind) {
        return CENTERED.contains(kind) ? Element.ALIGN_CENTER : Element.ALIGN_LEFT;
    }
}
