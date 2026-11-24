package dev.rgal.brackety.ranking;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.event.EventApiTest;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.Test;
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
                                "participants", "categories", "mats", "groups", "matches", "timeline")))
                .andExpect(jsonPath("$[0].title").value("Inscritos"))
                .andExpect(jsonPath("$[0].fields[0].title").value("Nombre"))
                .andExpect(jsonPath("$[0].fields[?(@.key=='birthDate')].sensitivity")
                        .value(org.hamcrest.Matchers.contains("PERSONAL")))
                .andExpect(jsonPath("$[0].fields[?(@.key=='birthDate')].kind")
                        .value(org.hamcrest.Matchers.contains("DATE")))
                .andExpect(jsonPath("$[0].fields[?(@.key=='guardianConsent')].sensitivity")
                        .value(org.hamcrest.Matchers.contains("MINORS")))
                .andExpect(jsonPath("$[0].fields[?(@.key=='club')].sensitivity")
                        .value(org.hamcrest.Matchers.contains("NORMAL")));

        call(get("/api/v1/events/" + eventId + "/exports/sheets?locale=en"), "club1")
                .andExpect(jsonPath("$[0].title").value("Participants"))
                .andExpect(jsonPath("$[0].fields[0].title").value("First name"));
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

    @Test
    void onlyTheClubExports() throws Exception {
        var body = """
                {"sheet":"participants","columns":["firstName"]}""";
        for (var user : List.of("ayudante1", "arbitro1")) {
            call(post("/api/v1/events/" + eventId + "/exports").content(body), user)
                    .andExpect(status().is4xxClientError());
            call(get("/api/v1/events/" + eventId + "/exports/sheets"), user).andExpect(status().is4xxClientError());
        }
    }

    private void participant(String firstName, BigDecimal weight) {
        var participant = new Participant(eventId, clock.instant());
        participant.update(firstName, "Prueba", LocalDate.of(2019, 3, 1), 110, true);
        participant.measure(null, weight);
        participants.save(participant);
    }

    private String export(String body) throws Exception {
        return call(post("/api/v1/events/" + eventId + "/exports").content(body), "club1")
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString(StandardCharsets.UTF_8);
    }

    private void refused(String body, String code) throws Exception {
        call(post("/api/v1/events/" + eventId + "/exports").content(body), "club1")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(code));
    }

    private static List<String> lines(String csv) {
        return Arrays.asList(csv.split("\r\n"));
    }
}
