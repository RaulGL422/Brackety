package dev.rgal.brackety.ranking;

import java.awt.Color;
import java.util.List;
import org.openpdf.text.Document;
import org.openpdf.text.Element;
import org.openpdf.text.Font;
import org.openpdf.text.FontFactory;
import org.openpdf.text.Phrase;
import org.openpdf.text.pdf.BaseFont;
import org.openpdf.text.pdf.PdfPCell;
import org.openpdf.text.pdf.PdfPageEventHelper;
import org.openpdf.text.pdf.PdfTemplate;
import org.openpdf.text.pdf.PdfWriter;

/** How the PDFs look ({@link StandingsPdf}, {@link TablePdf}): fonts, colours, cells and the footer. */
final class PdfStyle {

    static final Font TITLE = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16);
    static final Font SUBTITLE = FontFactory.getFont(FontFactory.HELVETICA, 10, Font.NORMAL, Color.DARK_GRAY);
    static final Font HEAD = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 9, Font.NORMAL, Color.WHITE);
    static final Font CELL = FontFactory.getFont(FontFactory.HELVETICA, 9);
    static final Font CELL_BOLD = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 9);
    static final Color HEAD_FILL = new Color(0x33, 0x3D, 0x4A);
    static final Color STRIPE = new Color(0xF4, 0xF5, 0xF7);
    private static final Color BORDER = new Color(0xD0, 0xD4, 0xDA);

    private PdfStyle() {}

    static PdfPCell center(String text, Font font) {
        return cell(text, font, Element.ALIGN_CENTER);
    }

    static PdfPCell cell(String text, Font font, int align) {
        var cell = new PdfPCell(new Phrase(text, font));
        cell.setHorizontalAlignment(align);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        cell.setPadding(4);
        cell.setBorderColor(BORDER);
        return cell;
    }

    static PdfPCell head(String text, int align) {
        var cell = cell(text, HEAD, align);
        cell.setBackgroundColor(HEAD_FILL);
        return cell;
    }

    static float[] toArray(List<Float> values) {
        var array = new float[values.size()];
        for (var i = 0; i < array.length; i++) {
            array[i] = values.get(i);
        }
        return array;
    }

    /**
     * {@code text} on the left ("Generado el…") and "Página X de Y" on the right: Y is only known at the end, so it
     * goes in a template filled when the document closes.
     */
    static final class Footer extends PdfPageEventHelper {

        private final String text;
        private final BaseFont font;
        private PdfTemplate total;

        Footer(String text) {
            this.text = text;
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
            canvas.showTextAligned(Element.ALIGN_LEFT, text, document.left(), y, 0);
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
