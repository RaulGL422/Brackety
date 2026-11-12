package dev.rgal.brackety.ranking;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.event.EventApiTest;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.zip.ZipInputStream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.ResultActions;

// A group of four 9-year-olds on mat 1 with one match played (3 - 1) and one with an undo.
class FullExportControllerTest extends EventApiTest {

    @Autowired
    ParticipantRepository participants;

    List<UUID> kids;

    @BeforeEach
    void playAMatch() throws Exception {
        kids = new ArrayList<>();
        var club = jdbc.sql("select id from event_organization where name = 'Club Demo Yoseikan'")
                .query(UUID.class)
                .single();
        for (var name : List.of("Ana", "Bea", "Cris", "Dani")) {
            var p = new Participant(eventId, clock.instant());
            p.update(name, "Prueba", LocalDate.of(2018, 1, 15), 130, true);
            p.setOrganizationId(club);
            kids.add(participants.save(p).getId());
        }
        var categoryId = jdbc.sql("select id from event_category where name = '9-10'")
                .query(UUID.class)
                .single();
        var ids = kids.stream().map(id -> "\"" + id + "\"").collect(Collectors.joining(","));
        call(post("/api/v1/events/" + eventId + "/groups").content("""
                                {"categoryId":"%s","groups":[{"participantIds":[%s]}]}""".formatted(categoryId, ids)), "ayudante1")
                .andExpect(status().isCreated());
        var first = match(kids.get(0), kids.get(1));
        act(first, "START", null);
        act(first, "POINT", "RED");
        act(first, "POINT", "RED");
        act(first, "POINT", "RED");
        act(first, "POINT", "BLUE");
        act(first, "POINT", "BLUE");
        act(first, "UNDO", null);
        clock.advance(Duration.ofMinutes(3));
        act(first, "FINISH", null);
    }

    @Test
    void theFullExportIsAZipOfReadableSheetsThePackageAndAReadme() throws Exception {
        var response = call(get("/api/v1/events/" + eventId + "/export/full"), "club1")
                .andExpect(status().isOk())
                .andExpect(header().string(
                                "Content-Disposition",
                                "attachment; filename=\"liga-yoseikan-2027-fase-1-tambo-2027-03-10.zip\""))
                .andReturn()
                .getResponse();
        assertThat(response.getContentType()).isEqualTo("application/zip");
        var files = unzip(response.getContentAsByteArray());

        assertThat(files.keySet())
                .containsExactly(
                        "LEEME.txt",
                        "participantes.csv",
                        "categorias.csv",
                        "tapices.csv",
                        "grupos.csv",
                        "combates.csv",
                        "linea-de-tiempo.csv",
                        "clasificacion-fase.csv",
                        "clasificacion-liga.csv",
                        "evento.brackety");
        assertThat(files.get("participantes.csv"))
                .startsWith(Csv.BOM + "Nombre;Apellidos;Fecha de nacimiento;Edad el día del evento")
                .contains("Ana;Prueba;15/01/2018;9;130;Club Demo Yoseikan;9-10;Por edad;Sí;;1;1;");
        assertThat(files.get("categorias.csv")).contains("9-10;9;10;Individual;;4;4;1;2;2;3");
        assertThat(files.get("tapices.csv")).contains("1;arbitro1;1;6;1");
        assertThat(files.get("grupos.csv")).contains(";ayudante1;1;Ana Prueba;;Club Demo Yoseikan;No");
        assertThat(files.get("combates.csv"))
                .contains("1;9-10;1;1;Ana Prueba;Club Demo Yoseikan;Bea Prueba;Club Demo Yoseikan;3;1;Ana Prueba;"
                        + "Fin del tiempo;Terminado;;10/03/2027;");
        assertThat(files.get("linea-de-tiempo.csv"))
                .contains(";Punto;Azul;Bea Prueba;;arbitro1;;Sí")
                .contains(";Deshacer;;;;arbitro1;Deshace la acción 6;No");
        assertThat(files.get("clasificacion-liga.csv")).contains("9-10;1;Oro (1.º);Ana;Prueba;Club Demo Yoseikan;10;3");
        assertThat(files.get("LEEME.txt")).contains("participantes.csv", "evento.brackety");
        assertThat(files.get("evento.brackety")).contains("\"schemaVersion\" : 2", "\"originId\"");
    }

    @Test
    void theResultsComeBackIntoTheSameEventOnceAndOnlyWithoutCompetitionOfItsOwn() throws Exception {
        var zip = call(get("/api/v1/events/" + eventId + "/export/full"), "club1")
                .andReturn()
                .getResponse()
                .getContentAsByteArray();
        var standings = standings();
        var actions = eventCount(
                "select count(*) from match_event e join fight_match m on m.id = e.match_id" + " where m.event_id = ?");
        // The club's server before the hall: the same event and entries, no competition.
        jdbc.sql("delete from fight_group where event_id = ?").param(eventId).update();

        importResults(zip, true)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.groups").value(1))
                .andExpect(jsonPath("$.matches").value(6))
                .andExpect(jsonPath("$.actions").value(actions))
                .andExpect(jsonPath("$.newParticipants").value(0));
        assertThat(eventCount("select count(*) from fight_group where event_id = ?"))
                .isZero();

        importResults(zip, false)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.alreadyImported").value(false));
        assertThat(standings()).isEqualTo(standings);
        assertThat(eventCount("select count(*) from match_event e join fight_match m on m.id = e.match_id"
                        + " where m.event_id = ? and e.target_event_id is not null"))
                .isOne();

        importResults(zip, false)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.alreadyImported").value(true));
        assertThat(eventCount("select count(*) from fight_group where event_id = ?"))
                .isOne();
    }

    @Test
    void aTeamsGhostMemberStaysAGhostAfterTheTrip() throws Exception {
        var teens = new ArrayList<UUID>();
        for (var name : List.of("Eva", "Fran", "Gema", "Hugo")) {
            var p = new Participant(eventId, clock.instant());
            p.update(name, "Prueba", LocalDate.of(2011, 6, 1), 160, true);
            teens.add(participants.save(p).getId());
        }
        var teams = "/api/v1/events/" + eventId + "/categories/"
                + jdbc.sql("select id from event_category where name = '15-16'")
                        .query(UUID.class)
                        .single()
                + "/teams";
        call(post(teams).content("""
                                {"participantIds":["%s","%s","%s"]}""".formatted(teens.get(0), teens.get(1), teens.get(2))), "ayudante1")
                .andExpect(status().isCreated());
        // Hugo alone, filled in by Eva and Fran as ghosts.
        call(
                        post(teams).content("""
                                {"participantIds":["%s","%s","%s"],"ghostIds":["%s","%s"]}""".formatted(
                                        teens.get(3), teens.get(0), teens.get(1), teens.get(0), teens.get(1))),
                        "ayudante1")
                .andExpect(status().isCreated());
        var zip = call(get("/api/v1/events/" + eventId + "/export/full"), "club1")
                .andReturn()
                .getResponse()
                .getContentAsByteArray();
        jdbc.sql("delete from fight_group where event_id = ?").param(eventId).update();
        jdbc.sql("delete from team where event_id = ?").param(eventId).update();

        importResults(zip, false).andExpect(status().isOk());

        assertThat(jdbc.sql("""
                        select p.first_name from team_member m join team t on t.id = m.team_id
                        join participant p on p.id = m.participant_id
                        where t.event_id = ? and m.ghost order by p.first_name""").param(eventId).query(String.class).list()).containsExactly("Eva", "Fran");
    }

    @Test
    void anEventWithCompetitionOfItsOwnOrAnotherEventsFileIsRefused() throws Exception {
        var zip = call(get("/api/v1/events/" + eventId + "/export/full"), "club1")
                .andReturn()
                .getResponse()
                .getContentAsByteArray();

        importResults(zip, false)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("RESULTS_CONFLICT"));

        var phase2 = JsonPath.read(
                call(post("/api/v1/events/" + eventId + "/league/phases").content("""
                                {"name":"Fase 2","date":"2027-04-10","discipline":"TAMBO","attendancePoints":10}"""), "club1")
                        .andReturn()
                        .getResponse()
                        .getContentAsString(),
                "$.eventId");
        importResults(phase2.toString(), zip, false)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("RESULTS_OTHER_EVENT"));
        importResults(zip, false, "ayudante1").andExpect(status().isForbidden());
        importResults("no es un fichero".getBytes(StandardCharsets.UTF_8), false)
                .andExpect(status().isBadRequest());
    }

    @Test
    void entriesAddedInTheHallComeAlongWithTheirResults() throws Exception {
        var zip = call(get("/api/v1/events/" + eventId + "/export/full"), "club1")
                .andReturn()
                .getResponse()
                .getContentAsByteArray();
        jdbc.sql("delete from fight_group where event_id = ?").param(eventId).update();
        // Dani was entered on the laptop only.
        participants.deleteById(kids.get(3));

        importResults(zip, false)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.newParticipants").value(1));
        assertThat(eventCount("select count(*) from group_member m join fight_group g on g.id = m.group_id"
                        + " where g.event_id = ?"))
                .isEqualTo(4);
    }

    private String standings() throws Exception {
        return call(get("/api/v1/events/" + eventId + "/standings"), "club1")
                .andReturn()
                .getResponse()
                .getContentAsString()
                .replaceAll("\"participantId\":\"[^\"]+\"", "");
    }

    private int eventCount(String sql) {
        return jdbc.sql(sql).param(eventId).query(Integer.class).single();
    }

    private ResultActions importResults(byte[] file, boolean dryRun) throws Exception {
        return importResults(eventId.toString(), file, dryRun);
    }

    private ResultActions importResults(byte[] file, boolean dryRun, String username) throws Exception {
        return importResults(eventId.toString(), file, dryRun, username);
    }

    private ResultActions importResults(String event, byte[] file, boolean dryRun) throws Exception {
        return importResults(event, file, dryRun, "club1");
    }

    private ResultActions importResults(String event, byte[] file, boolean dryRun, String username) throws Exception {
        var token = auth.login(username, username, "127.0.0.1").accessToken();
        return mvc.perform(post("/api/v1/events/" + event + "/import/results")
                .param("dryRun", String.valueOf(dryRun))
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .content(file));
    }

    private static Map<String, String> unzip(byte[] zip) throws Exception {
        var files = new LinkedHashMap<String, String>();
        try (var in = new ZipInputStream(new ByteArrayInputStream(zip))) {
            for (var entry = in.getNextEntry(); entry != null; entry = in.getNextEntry()) {
                files.put(entry.getName(), new String(in.readAllBytes(), StandardCharsets.UTF_8));
            }
        }
        return files;
    }

    private UUID match(UUID red, UUID blue) {
        return jdbc.sql("select id from fight_match where red_participant_id = ? and blue_participant_id = ?")
                .params(red, blue)
                .query(UUID.class)
                .single();
    }

    private void act(UUID match, String type, String side) throws Exception {
        call(
                        post("/api/v1/matches/" + match + "/events").content("""
                                {"type":"%s","side":%s,"reason":null,"knownEvents":%d}""".formatted(
                                        type, side == null ? "null" : "\"" + side + "\"", knownEvents(match))),
                        "arbitro1")
                .andExpect(status().isOk());
    }
}
