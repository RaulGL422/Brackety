package dev.rgal.brackety.participant.importing;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.zip.ZipInputStream;
import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;

/**
 * The first sheet of an Excel file as text, one line per row and cells split by " | ": Claude does
 * not read .xlsx. Dates (numbers with a date format in Excel) come out as dd/MM/yyyy.
 */
final class XlsxText {

    // Generous for a list of 200 participants; stops a small zip that unpacks into gigabytes.
    private static final long MAX_ENTRY_BYTES = 20L * 1024 * 1024;
    private static final LocalDate EXCEL_EPOCH = LocalDate.of(1899, 12, 30);
    private static final DateTimeFormatter DAY = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    private XlsxText() {}

    static String of(byte[] xlsx) {
        try {
            var parts = unzip(xlsx);
            var sheet = parts.get("xl/worksheets/sheet1.xml");
            if (sheet == null) {
                throw new ListReadException("The Excel file has no first sheet");
            }
            var strings = sharedStrings(parts.get("xl/sharedStrings.xml"));
            var dateStyles = dateStyles(parts.get("xl/styles.xml"));
            return rows(xml(sheet), strings, dateStyles);
        } catch (IOException | RuntimeException e) {
            if (e instanceof ListReadException read) {
                throw read;
            }
            throw new ListReadException("Not a readable Excel file", e);
        }
    }

    private static String rows(Document sheet, List<String> strings, List<Boolean> dateStyles) {
        var lines = new ArrayList<String>();
        for (var row : elements(sheet.getDocumentElement(), "row")) {
            var cells = new TreeMap<Integer, String>();
            var next = 0;
            for (var cell : elements(row, "c")) {
                var ref = cell.getAttribute("r");
                var column = ref.isEmpty() ? next : column(ref);
                cells.put(column, value(cell, strings, dateStyles));
                next = column + 1;
            }
            if (cells.values().stream().allMatch(String::isBlank)) {
                continue;
            }
            var line = new ArrayList<String>();
            for (int i = 0; i <= cells.lastKey(); i++) {
                line.add(cells.getOrDefault(i, ""));
            }
            lines.add(String.join(" | ", line));
        }
        return String.join("\n", lines);
    }

    private static String value(Element cell, List<String> strings, List<Boolean> dateStyles) {
        var type = cell.getAttribute("t");
        if (type.equals("inlineStr")) {
            return cell.getTextContent().strip();
        }
        var v = child(cell, "v");
        if (v == null) {
            return "";
        }
        var raw = v.getTextContent().strip();
        if (type.equals("s")) {
            return strings.get(Integer.parseInt(raw));
        }
        if (type.isEmpty() || type.equals("n")) {
            var style = cell.getAttribute("s");
            var index = style.isEmpty() ? 0 : Integer.parseInt(style);
            if (index < dateStyles.size() && dateStyles.get(index)) {
                return DAY.format(EXCEL_EPOCH.plusDays((long) Double.parseDouble(raw)));
            }
            return raw.endsWith(".0") ? raw.substring(0, raw.length() - 2) : raw;
        }
        return raw;
    }

    private static List<String> sharedStrings(byte[] part) throws IOException {
        var result = new ArrayList<String>();
        if (part != null) {
            for (var si : elements(xml(part).getDocumentElement(), "si")) {
                result.add(si.getTextContent().strip());
            }
        }
        return result;
    }

    /** For each cell style (position = the cell's "s"), whether it shows a date. */
    private static List<Boolean> dateStyles(byte[] part) throws IOException {
        var result = new ArrayList<Boolean>();
        if (part == null) {
            return result;
        }
        var root = xml(part).getDocumentElement();
        var custom = new HashMap<Integer, String>();
        var numFmts = child(root, "numFmts");
        if (numFmts != null) {
            for (var f : elements(numFmts, "numFmt")) {
                custom.put(Integer.parseInt(f.getAttribute("numFmtId")), f.getAttribute("formatCode"));
            }
        }
        var cellXfs = child(root, "cellXfs");
        if (cellXfs != null) {
            for (var xf : elements(cellXfs, "xf")) {
                var id = xf.getAttribute("numFmtId");
                result.add(!id.isEmpty() && isDateFormat(Integer.parseInt(id), custom));
            }
        }
        return result;
    }

    // Excel's built-in date formats, or a custom one with day/month/year parts outside quotes.
    private static boolean isDateFormat(int id, Map<Integer, String> custom) {
        if ((id >= 14 && id <= 22) || (id >= 45 && id <= 47)) {
            return true;
        }
        var code = custom.get(id);
        if (code == null) {
            return false;
        }
        var unquoted =
                code.replaceAll("\"[^\"]*\"", "").replaceAll("\\[[^]]*]", "").toLowerCase();
        return unquoted.matches(".*[dy].*");
    }

    private static int column(String ref) {
        var column = 0;
        for (var ch : ref.toCharArray()) {
            if (!Character.isLetter(ch)) {
                break;
            }
            column = column * 26 + (Character.toUpperCase(ch) - 'A' + 1);
        }
        return column - 1;
    }

    private static Map<String, byte[]> unzip(byte[] zip) throws IOException {
        var parts = new HashMap<String, byte[]>();
        try (var in = new ZipInputStream(new ByteArrayInputStream(zip))) {
            for (var entry = in.getNextEntry(); entry != null; entry = in.getNextEntry()) {
                var name = entry.getName();
                if (name.equals("xl/worksheets/sheet1.xml")
                        || name.equals("xl/sharedStrings.xml")
                        || name.equals("xl/styles.xml")) {
                    parts.put(name, limited(in));
                }
            }
        }
        return parts;
    }

    private static byte[] limited(InputStream in) throws IOException {
        var out = new ByteArrayOutputStream();
        var buffer = new byte[8192];
        long total = 0;
        for (int n; (n = in.read(buffer)) > 0; ) {
            total += n;
            if (total > MAX_ENTRY_BYTES) {
                throw new ListReadException("The Excel file is too large");
            }
            out.write(buffer, 0, n);
        }
        return out.toByteArray();
    }

    private static Document xml(byte[] part) throws IOException {
        try {
            var factory = DocumentBuilderFactory.newInstance();
            // No external entities or DTDs: the file comes from outside.
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_DTD, "");
            factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_SCHEMA, "");
            factory.setNamespaceAware(false);
            return factory.newDocumentBuilder().parse(new ByteArrayInputStream(part));
        } catch (Exception e) {
            throw new IOException("Unreadable XML in the Excel file", e);
        }
    }

    private static List<Element> elements(Element parent, String tag) {
        var result = new ArrayList<Element>();
        var nodes = parent.getElementsByTagName(tag);
        for (int i = 0; i < nodes.getLength(); i++) {
            result.add((Element) nodes.item(i));
        }
        return result;
    }

    private static Element child(Element parent, String tag) {
        for (Node n = parent.getFirstChild(); n != null; n = n.getNextSibling()) {
            if (n instanceof Element e && e.getNodeName().equals(tag)) {
                return e;
            }
        }
        return null;
    }
}
