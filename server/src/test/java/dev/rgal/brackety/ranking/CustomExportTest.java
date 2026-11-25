package dev.rgal.brackety.ranking;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.event.EventApiTest;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.io.IOException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.zip.ZipFile;
import org.junit.jupiter.api.Test;
import org.openpdf.text.pdf.PdfReader;
import org.openpdf.text.pdf.parser.PdfTextExtractor;
import org.springframework.beans.factory.annotation.Autowired;

// Custom exports (docs/producto/exportaciones.md, step 1): the club picks the sheet, its columns and the row order.
class CustomExportTest extends EventApiTest {

    @Autowired
    ParticipantRepository participants;

    @Test
    void eachSheetOffersItsFieldsWithKindAndSensitivityInBothLanguages() throws Exception {
        call(get("/api/v1/events/" + eventId + "/exports/sheets"), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].key")
                        .value(org.hamcrest.Matchers.contains(
                                "participants",
                                "categories",
                                "mats",
                                "groups",
                                "matches",
                                "timeline",
                                "standings",
                                "league")))
                .andExpect(jsonPath("$[0].title").value("Inscritos"))
                .andExpect(jsonPath("$[0].fields[0].title").value("Nombre"))
                .andExpect(jsonPath("$[0].fields[?(@.key=='birthDate')].sensitivity")
                        .value(org.hamcrest.Matchers.contains("PERSONAL")))
                .andExpect(jsonPath("$[0].fields[?(@.key=='birthDate')].kind")
                        .value(org.hamcrest.Matchers.contains("DATE")))
                .andExpect(jsonPath("$[0].fields[?(@.key=='guardianConsent')].sensitivity")
                        .value(org.hamcrest.Matchers.contains("MINORS")))
                .andExpect(jsonPath("$[0].fields[?(@.key=='club')].sensitivity")
                        .value(org.hamcrest.Matchers.contains("NORMAL")))
                // The league has three columns for each of its phases.
                .andExpect(jsonPath("$[7].fields[?(@.key=='phase1Attendance')].title")
                        .value(org.hamcrest.Matchers.contains("Fase 1: asistencia")))
                .andExpect(jsonPath("$[7].fields[?(@.key=='phase1Total')].title")
                        .value(org.hamcrest.Matchers.contains("Fase 1: total")));

        call(get("/api/v1/events/" + eventId + "/exports/sheets?locale=en"), "club1")
                .andExpect(jsonPath("$[0].title").value("Participants"))
                .andExpect(jsonPath("$[0].fields[0].title").value("First name"))
                .andExpect(jsonPath("$[7].fields[?(@.key=='phase1Attendance')].title")
                        .value(org.hamcrest.Matchers.contains("Phase 1: attendance")));
    }

    @Test
    void theStandingsAreSheetsLikeTheRest() throws Exception {
        participant("Bea", null);
        participant("Ana", null);

        var phase = export("""
                {"sheet":"standings","columns":["firstName","category"],
                 "sort":[{"column":"firstName","descending":true}],"locale":"en"}""");
        var league = export("""
                {"sheet":"league","columns":["firstName","phase1Attendance"],
                 "sort":[{"column":"firstName","descending":false}]}""");

        assertThat(lines(phase)).containsExactly(Csv.BOM + "First name;Category", "Bea;7-8", "Ana;7-8");
        assertThat(lines(league).getFirst()).isEqualTo(Csv.BOM + "Nombre;Fase 1: asistencia");
        assertThat(lines(league).subList(1, 3)).allMatch(line -> line.matches("(Ana|Bea);\\d+"));
    }

    @Test
    void theClubPicksTheColumnsTheirOrderAndHowTheRowsSort() throws Exception {
        participant("Bea", new BigDecimal("25.0"));
        participant("Álvaro", new BigDecimal("30.5"));
        participant("Ana", new BigDecimal("25.0"));
        participant("Carla", null);

        var csv = export("""
                {"sheet":"participants","columns":["weightKg","firstName"],
                 "sort":[{"column":"weightKg","descending":true},{"column":"firstName","descending":false}],
                 "locale":"en"}""");

        // Spanish order for names (Á next to A), the empty weight last also when descending.
        assertThat(lines(csv))
                .containsExactly(Csv.BOM + "Weight (kg);First name", "30,5;Álvaro", "25,0;Ana", "25,0;Bea", ";Carla");
    }

    @Test
    void withoutASortTheRowsKeepTheSheetsOwnOrder() throws Exception {
        participant("Bea", null);
        participant("Ana", null);

        var csv = export("""
                {"sheet":"participants","columns":["firstName","lastName"]}""");

        assertThat(lines(csv)).containsExactly(Csv.BOM + "Nombre;Apellidos", "Ana;Prueba", "Bea;Prueba");
    }

    @Test
    void thePreviewShowsTheFirstTwentyRowsAndHowManyThereAre() throws Exception {
        for (int i = 0; i < 25; i++) {
            participant("Alumno%02d".formatted(i), null);
        }

        call(post("/api/v1/events/" + eventId + "/exports/preview").content("""
                                {"sheet":"participants","columns":["firstName","birthDate"]}"""), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.headers").value(org.hamcrest.Matchers.contains("Nombre", "Fecha de nacimiento")))
                .andExpect(jsonPath("$.rows.length()").value(20))
                .andExpect(jsonPath("$.rows[0]").value(org.hamcrest.Matchers.contains("Alumno00", "01/03/2019")))
                .andExpect(jsonPath("$.totalRows").value(25));
    }

    @Test
    void anUnknownSheetOrColumnOrARepeatedColumnIsRefusedWithItsCode() throws Exception {
        refused("""
                {"sheet":"payments","columns":["firstName"]}""", "EXPORT_UNKNOWN_SHEET");
        refused("""
                {"sheet":"participants","columns":["firstName","password"]}""", "EXPORT_UNKNOWN_COLUMN");
        refused("""
                {"sheet":"participants","columns":["firstName"],"sort":[{"column":"x","descending":false}]}""", "EXPORT_UNKNOWN_COLUMN");
        refused("""
                {"sheet":"participants","columns":["firstName","firstName"]}""", "EXPORT_REPEATED_COLUMN");
    }

    @Test
    void aFormulaInANameIsNeutralisedAsInEveryDownload() throws Exception {
        participant("=HYPERLINK(\"x\")", null);

        var csv = export("""
                {"sheet":"participants","columns":["firstName"]}""");

        assertThat(lines(csv)).containsExactly(Csv.BOM + "Nombre", "\"'=HYPERLINK(\"\"x\"\")\"");
    }

    // The club and whoever enters people export; the personal columns need their own permission (exportaciones.md).
    @Test
    void aHelperExportsWithParticipantsAndSeesPersonalColumnsOnlyWithPersonalData() throws Exception {
        participant("Ana", new BigDecimal("25.0"));
        var names = """
                {"sheet":"participants","columns":["firstName"]}""";
        var weights = """
                {"sheet":"participants","columns":["firstName","weightKg"]}""";
        call(post("/api/v1/events/" + eventId + "/exports").content(names), "ayudante1")
                .andExpect(status().isForbidden());
        call(get("/api/v1/events/" + eventId + "/exports/sheets"), "ayudante1").andExpect(status().isForbidden());

        grant("ayudante1", "PARTICIPANTS");
        call(get("/api/v1/events/" + eventId + "/exports/sheets"), "ayudante1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].fields[?(@.key=='weightKg')]").isEmpty())
                .andExpect(jsonPath("$[0].fields[?(@.key=='guardianConsent')]").isEmpty())
                .andExpect(jsonPath("$[0].fields[?(@.key=='club')]").isNotEmpty());
        assertThat(lines(export(names, "ayudante1"))).containsExactly(Csv.BOM + "Nombre", "Ana");
        call(post("/api/v1/events/" + eventId + "/exports").content(weights), "ayudante1")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("EXPORT_UNKNOWN_COLUMN"));

        grant("ayudante1", "PARTICIPANTS", "PERSONAL_DATA");
        assertThat(lines(export(weights, "ayudante1"))).containsExactly(Csv.BOM + "Nombre;Peso (kg)", "Ana;25,0");
        call(post("/api/v1/events/" + eventId + "/exports").content(names), "arbitro1")
                .andExpect(status().isForbidden());
    }

    // «Para publicar»: first name and the initial, never a personal column, also in the preview.
    @Test
    void forPublishingShortensTheNamesAndLeavesOutThePersonalColumns() throws Exception {
        participant("Ana", new BigDecimal("25.0"));

        var csv = export("""
                {"sheet":"participants","columns":["firstName","lastName","club"],"forPublishing":true}""");
        assertThat(lines(csv).get(1)).startsWith("Ana;P.;");
        call(post("/api/v1/events/" + eventId + "/exports/preview").content("""
                                {"sheet":"standings","columns":["firstName","lastName"],"forPublishing":true}"""), "club1")
                .andExpect(jsonPath("$.rows[0]").value(org.hamcrest.Matchers.contains("Ana", "P.")));
        refused("""
                {"sheet":"participants","columns":["firstName","weightKg"],"forPublishing":true}""", "EXPORT_UNKNOWN_COLUMN");
    }

    @Test
    void filtersKeepTheRowsWithOneOfTheValuesAndInsideTheRange() throws Exception {
        participant("Ana", new BigDecimal("25.0"));
        participant("Bea", new BigDecimal("30.5"));
        participant("Carla", new BigDecimal("40.0"), 2017);

        var csv = export("""
                {"sheet":"participants","columns":["firstName","category"],
                 "filters":[{"column":"category","anyOf":["7-8"]},{"column":"weightKg","min":26}]}""");

        assertThat(lines(csv)).containsExactly(Csv.BOM + "Nombre;Categoría", "Bea;7-8");
        refused("""
                {"sheet":"participants","columns":["firstName"],"filters":[{"column":"firstName","min":1}]}""", "EXPORT_FILTER_NOT_A_NUMBER");
    }

    @Test
    void splitByGivesOneFilePerValueInAZipWithTheColumnsOwnTitles() throws Exception {
        participant("Bea", null);
        participant("Ana", null);
        participant("Carla", null, 2017);

        var answer = call(post("/api/v1/events/" + eventId + "/exports").content("""
                                {"sheet":"participants","columns":["firstName"],"titles":{"firstName":"Alumno"},
                                 "splitBy":"category"}"""), "club1")
                .andExpect(status().isOk())
                .andReturn()
                .getResponse();

        assertThat(answer.getContentType()).isEqualTo("application/zip");
        assertThat(answer.getHeader("Content-Disposition")).contains(".zip");
        var files = unzip(answer.getContentAsByteArray());
        assertThat(files.keySet())
                .satisfiesExactly(
                        name -> assertThat(name).endsWith("participantes_7-8.csv"),
                        name -> assertThat(name).endsWith("participantes_9-10.csv"));
        assertThat(files.values().stream().map(CustomExportTest::lines))
                .containsExactly(List.of(Csv.BOM + "Alumno", "Ana", "Bea"), List.of(Csv.BOM + "Alumno", "Carla"));
        refused("""
                {"sheet":"participants","columns":["firstName"],"titles":{"club":"Escuela"}}""", "EXPORT_UNKNOWN_COLUMN");
        refused("""
                {"sheet":"participants","columns":["firstName"],"splitBy":"belt"}""", "EXPORT_UNKNOWN_COLUMN");
    }

    @Test
    void anExcelWorkbookHasAWorksheetPerValueWithRealNumbersAndDatesAndNoFormulas() throws Exception {
        participant("Ana", new BigDecimal("25.5"));
        participant("=1+1", null);
        participant("Carla", new BigDecimal("40.0"), 2017);

        var answer = call(post("/api/v1/events/" + eventId + "/exports").content("""
                                {"sheet":"participants","columns":["firstName","weightKg","birthDate"],
                                 "splitBy":"category","format":"xlsx"}"""), "club1")
                .andExpect(status().isOk())
                .andReturn()
                .getResponse();

        assertThat(answer.getContentType()).isEqualTo(Xlsx.CONTENT_TYPE);
        assertThat(answer.getHeader("Content-Disposition")).contains("participantes.xlsx");
        var files = unzip(answer.getContentAsByteArray());
        assertThat(files.get("xl/workbook.xml")).contains("name=\"7-8\"", "name=\"9-10\"");
        assertThat(files.get("xl/sharedStrings.xml")).contains("Nombre", "Peso (kg)", "Ana", "=1+1", "Carla");
        var first = files.get("xl/worksheets/sheet1.xml");
        // 25.5 as a number, 1 March 2019 as Excel's day 43525, and the name that looks like a formula, as a text.
        assertThat(first).contains("<v>25.5</v>", "<v>43525").doesNotContain("<f>");
    }

    @Test
    void aPdfHasAPagePerValueWithItsTitleTheEventAndTheVersionAndTurnsWhenWide() throws Exception {
        participant("Ana", new BigDecimal("25.5"));
        participant("Carla", null, 2017);

        var split = call(post("/api/v1/events/" + eventId + "/exports").content("""
                                {"sheet":"participants","columns":["firstName","weightKg"],"splitBy":"category",
                                 "format":"pdf","title":"Lista para la mesa"}"""), "club1")
                .andExpect(status().isOk())
                .andReturn()
                .getResponse();

        assertThat(split.getContentType()).isEqualTo("application/pdf");
        assertThat(split.getHeader("Content-Disposition")).contains("participantes.pdf");
        var reader = new PdfReader(split.getContentAsByteArray());
        var text = new PdfTextExtractor(reader);
        assertThat(reader.getNumberOfPages()).isEqualTo(2);
        assertThat(text.getTextFromPage(1))
                .contains("7-8", "Lista para la mesa", "Nombre", "Peso (kg)", "Ana", "25,5", "Brackety local")
                .doesNotContain("Carla");
        assertThat(text.getTextFromPage(2)).contains("9-10", "Carla");
        assertThat(reader.getPageSizeWithRotation(1).getWidth())
                .isLessThan(reader.getPageSizeWithRotation(1).getHeight());

        var wide = new PdfReader(
                call(post("/api/v1/events/" + eventId + "/exports").content("""
                                {"sheet":"participants","format":"pdf","columns":["firstName","lastName","age",
                                 "sex","club","category","team"]}"""), "club1")
                        .andExpect(status().isOk())
                        .andReturn()
                        .getResponse()
                        .getContentAsByteArray());
        assertThat(new PdfTextExtractor(wide).getTextFromPage(1)).contains("Inscritos");
        assertThat(wide.getPageSizeWithRotation(1).getWidth())
                .isGreaterThan(wide.getPageSizeWithRotation(1).getHeight());
    }

    private void participant(String firstName, BigDecimal weight) {
        participant(firstName, weight, 2019);
    }

    private void participant(String firstName, BigDecimal weight, int bornIn) {
        var participant = new Participant(eventId, clock.instant());
        participant.update(firstName, "Prueba", LocalDate.of(bornIn, 3, 1), 110, true);
        participant.measure(null, weight);
        participants.save(participant);
    }

    private String export(String body) throws Exception {
        return export(body, "club1");
    }

    private String export(String body, String user) throws Exception {
        return call(post("/api/v1/events/" + eventId + "/exports").content(body), user)
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString(StandardCharsets.UTF_8);
    }

    private void grant(String user, String... permissions) throws Exception {
        call(
                        put("/api/v1/events/" + eventId + "/staff/" + accountId(user) + "/permissions")
                                .content("{\"permissions\":[\"" + String.join("\",\"", permissions) + "\"]}"),
                        "club1")
                .andExpect(status().is2xxSuccessful());
    }

    private void refused(String body, String code) throws Exception {
        call(post("/api/v1/events/" + eventId + "/exports").content(body), "club1")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(code));
    }

    // Through the zip's index, as Excel reads it: the .xlsx is written as a stream.
    private static Map<String, String> unzip(byte[] zip) throws IOException {
        var file = Files.createTempFile("export", ".zip");
        try {
            Files.write(file, zip);
            var files = new LinkedHashMap<String, String>();
            try (var archive = new ZipFile(file.toFile(), StandardCharsets.UTF_8)) {
                for (var entry : Collections.list(archive.entries())) {
                    try (var in = archive.getInputStream(entry)) {
                        files.put(entry.getName(), new String(in.readAllBytes(), StandardCharsets.UTF_8));
                    }
                }
            }
            return files;
        } finally {
            Files.delete(file);
        }
    }

    private static List<String> lines(String csv) {
        return Arrays.asList(csv.split("\r\n"));
    }
}
