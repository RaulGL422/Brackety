package dev.rgal.brackety.participant.importing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.hasSize;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.event.EventApiTest;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import dev.rgal.brackety.participant.importing.dto.ImportRow;
import java.time.Duration;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockMultipartHttpServletRequestBuilder;

// The demo event is on 2027-03-10: someone born on 2018-01-01 is 9 (category "9-10").
class ParticipantImportControllerTest extends EventApiTest {

    private static final MockMultipartFile PHOTO =
            new MockMultipartFile("files", "lista.png", "image/png", new byte[] {1, 2, 3});

    @MockitoBean
    ListReader reader;

    @Autowired
    ParticipantRepository participants;

    @BeforeEach
    void readerIsSetUp() {
        when(reader.isAvailable()).thenReturn(true);
    }

    @Test
    void aListIsReadAndCheckedWithoutKeepingAnything() throws Exception {
        when(reader.read(any()))
                .thenReturn(List.of(
                        row("Ana", "Prueba", LocalDate.of(2018, 1, 1), null),
                        row("Bea", "Prueba", LocalDate.of(2018, 1, 1), "cat. 7-8"),
                        new ImportRow("Irene", "Vidal", null, "30/02/2017", 300, null, null, List.of("lastName"))));

        read(PHOTO)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(3)))
                .andExpect(jsonPath("$[0].categoryName").value("9-10"))
                .andExpect(jsonPath("$[0].errors", empty()))
                .andExpect(jsonPath("$[1].errors[0].code").value("CATEGORY_MISMATCH"))
                .andExpect(jsonPath("$[1].indicatedCategoryName").value("7-8"))
                .andExpect(jsonPath("$[1].ageCategoryName").value("9-10"))
                .andExpect(jsonPath("$[2].errors[*].code", contains("INVALID_DATE", "HEIGHT_OUT_OF_RANGE")))
                .andExpect(jsonPath("$[2].errors[0].detail").value("30/02/2017"))
                .andExpect(jsonPath("$[2].warnings[0].code").value("UNSURE"));
        assertThat(count("participant")).isZero();
    }

    @Test
    void readingNeedsTheConsentTheClubAndAReader() throws Exception {
        upload(multipart(path("/read")).file(PHOTO), "club1").andExpect(status().isBadRequest());
        read(new MockMultipartFile("files", "virus.exe", "application/octet-stream", new byte[] {1}))
                .andExpect(status().isBadRequest());
        upload(multipart(path("/read")).file(PHOTO).param("consentVersion", "v1"), "ayudante1")
                .andExpect(status().isForbidden());

        when(reader.isAvailable()).thenReturn(false);
        call(get(path("/available")), "club1").andExpect(jsonPath("$.available").value(false));
        read(PHOTO).andExpect(status().isServiceUnavailable());
    }

    @Test
    void aListThatCannotBeReadSaysSoAndTheReadsPerHourAreLimited() throws Exception {
        when(reader.read(any())).thenThrow(new ListReadException("broken"));
        read(PHOTO).andExpect(status().isBadGateway());

        for (int i = 1; i < ParticipantImportService.MAX_READS_PER_HOUR; i++) {
            read(PHOTO);
        }
        read(PHOTO).andExpect(status().isTooManyRequests());
        clock.advance(Duration.ofMinutes(61));
        read(PHOTO).andExpect(status().isBadGateway());
    }

    @Test
    void registeringIsAllOrNone() throws Exception {
        var ana = row("Ana", "Prueba", LocalDate.of(2018, 1, 1), null);
        var noDate = row("Bea", "Prueba", null, null);

        register(ana, noDate)
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.registered").value(0))
                .andExpect(jsonPath("$.rows[1].errors[0].code").value("MISSING"));
        assertThat(count("participant")).isZero();

        register(ana, row("Bea", "Prueba", LocalDate.of(2017, 6, 1), null))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.registered").value(2));
        assertThat(count("participant")).isEqualTo(2);
        assertThat(participants.findAll()).allMatch(Participant::hasGuardianConsent);
        assertThat(jdbc.sql("select consent_version from participant_import")
                        .query(String.class)
                        .single())
                .isEqualTo("v1");

        register(row("ANA ", "prueba", LocalDate.of(2018, 1, 1), null))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.rows[0].errors[0].code").value("ALREADY_REGISTERED"));
        register(ana, ana)
                .andExpect(jsonPath("$.rows[1].errors[*].code", contains("ALREADY_REGISTERED", "DUPLICATE_IN_LIST")));
    }

    @Test
    void registeringNeedsTheCurrentConsent() throws Exception {
        call(post(path("")).content(json(List.of(row("Ana", "Prueba", LocalDate.of(2018, 1, 1), null)), "v0")), "club1")
                .andExpect(status().isBadRequest());
        assertThat(count("participant")).isZero();
    }

    @Test
    void theClubPicksTheCategoryWhenTheWrittenOneDoesNotMatchTheAge() throws Exception {
        var written = row("Bea", "Prueba", LocalDate.of(2018, 1, 1), "7-8");
        call(post(path("/check")).content(json(List.of(written), null)), "club1")
                .andExpect(jsonPath("$[0].errors[0].code").value("CATEGORY_MISMATCH"));

        var chosen =
                new ImportRow("Bea", "Prueba", LocalDate.of(2018, 1, 1), null, null, "7-8", category("7-8"), List.of());
        register(chosen).andExpect(status().isCreated());

        // The chosen category wins over the age everywhere: groups and registrations.
        call(get("/api/v1/events/" + eventId + "/categories/" + category("7-8") + "/participants"), "ayudante1")
                .andExpect(jsonPath("$[*].firstName", contains("Bea")));
        call(get("/api/v1/events/" + eventId + "/participants"), "club1")
                .andExpect(jsonPath("$[0].categoryName").value("7-8"))
                .andExpect(
                        jsonPath("$[0].chosenCategoryId").value(category("7-8").toString()));
    }

    @Test
    void theRegistrationFormChecksTheChosenCategory() throws Exception {
        var body = """
                {"firstName":"Ana","lastName":"Prueba","birthDate":"2018-01-01","guardianConsent":true,
                 "categoryId":"%s"}""";
        call(post("/api/v1/events/" + eventId + "/participants").content(body.formatted(UUID.randomUUID())), "club1")
                .andExpect(status().isBadRequest());
        call(post("/api/v1/events/" + eventId + "/participants").content(body.formatted(category("11-12"))), "club1")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.categoryName").value("11-12"));
    }

    @Test
    void theChosenCategoryIsLockedOnceInAGroup() throws Exception {
        var ids = new java.util.ArrayList<String>();
        for (var name : List.of("A", "B", "C", "D")) {
            var created = call(
                            post("/api/v1/events/" + eventId + "/participants").content("""
                                    {"firstName":"%s","lastName":"Prueba","birthDate":"2018-01-01","guardianConsent":true}""".formatted(name)), "club1")
                    .andReturn()
                    .getResponse()
                    .getContentAsString();
            ids.add(com.jayway.jsonpath.JsonPath.read(created, "$.id"));
        }
        call(
                        post("/api/v1/events/" + eventId + "/groups").content("""
                                {"categoryId":"%s","groups":[{"participantIds":["%s","%s","%s","%s"]}]}""".formatted(
                                        category("9-10"), ids.get(0), ids.get(1), ids.get(2), ids.get(3))),
                        "ayudante1")
                .andExpect(status().isCreated());

        call(
                        put("/api/v1/events/" + eventId + "/participants/" + ids.get(0))
                                .content("""
                                {"firstName":"A","lastName":"Prueba","birthDate":"2018-01-01","guardianConsent":true,
                                 "categoryId":"%s"}""".formatted(category("7-8"))),
                        "club1")
                .andExpect(status().isConflict());
    }

    private ResultActions read(MockMultipartFile file) throws Exception {
        return upload(multipart(path("/read")).file(file).param("consentVersion", "v1"), "club1");
    }

    private ResultActions register(ImportRow... rows) throws Exception {
        return call(post(path("")).content(json(List.of(rows), "v1")), "club1");
    }

    private ResultActions upload(MockMultipartHttpServletRequestBuilder request, String user) throws Exception {
        var token = auth.login(user, user, "127.0.0.1").accessToken();
        return mvc.perform(request.header(HttpHeaders.AUTHORIZATION, "Bearer " + token));
    }

    private String json(List<ImportRow> rows, String consentVersion) throws Exception {
        return new tools.jackson.databind.json.JsonMapper()
                .writeValueAsString(
                        java.util.Map.of("rows", rows, "consentVersion", consentVersion == null ? "" : consentVersion));
    }

    private static ImportRow row(String first, String last, LocalDate birth, String category) {
        return new ImportRow(first, last, birth, null, 130, category, null, List.of());
    }

    private String path(String rest) {
        return "/api/v1/events/" + eventId + "/participants/import" + rest;
    }

    private UUID category(String name) {
        return jdbc.sql("select id from event_category where name = ?")
                .param(name)
                .query(UUID.class)
                .single();
    }
}
