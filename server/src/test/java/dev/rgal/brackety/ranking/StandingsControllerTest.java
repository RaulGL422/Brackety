package dev.rgal.brackety.ranking;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.event.EventApiTest;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

// One group of 9-year-olds on mat 1 (arbitro1): three fighters and a ghost; one more participant not grouped.
class StandingsControllerTest extends EventApiTest {

    @Autowired
    ParticipantRepository participants;

    List<UUID> fighters;
    UUID ghost;
    UUID notGrouped;

    @BeforeEach
    void playTwoMatches() throws Exception {
        fighters = new ArrayList<>();
        fighters.add(participant("Ana"));
        fighters.add(participant("Bea"));
        fighters.add(participant("=HYPERLINK(\"x\")"));
        ghost = participant("Fantasma");
        notGrouped = participant("Zoe");
        var categoryId = jdbc.sql("select id from event_category where name = '9-10'")
                .query(UUID.class)
                .single();
        var ids = fighters.stream().map(id -> "\"" + id + "\"").collect(Collectors.joining(","));
        call(post("/api/v1/events/" + eventId + "/groups").content("""
                                {"categoryId":"%s","groups":[{"participantIds":[%s],"ghostId":"%s"}]}""".formatted(categoryId, ids, ghost)), "ayudante1")
                .andExpect(status().isCreated());

        // Ana 3 - Bea 15: both keep what they scored.
        var first = match(fighters.get(0), fighters.get(1));
        referee(first, "START", null, null);
        for (int i = 0; i < 3; i++) {
            referee(first, "POINT", "RED", null);
        }
        for (int i = 0; i < 15; i++) {
            referee(first, "POINT", "BLUE", null);
        }
        referee(first, "FINISH", null, null);
        // Third fighter 4 - ghost 6: the ghost scores nothing for the ranking.
        var second = match(fighters.get(2), ghost);
        referee(second, "START", null, null);
        for (int i = 0; i < 4; i++) {
            referee(second, "POINT", "RED", null);
        }
        for (int i = 0; i < 6; i++) {
            referee(second, "POINT", "BLUE", null);
        }
        clock.advance(Duration.ofMinutes(3));
        referee(second, "FINISH", null, null);
    }

    @Test
    void attendancePlusMatchPointsGhostsExcludedAndTiesShareThePosition() throws Exception {
        call(get("/api/v1/events/" + eventId + "/standings"), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(5)))
                .andExpect(jsonPath("$[0].firstName").value("Bea"))
                .andExpect(jsonPath("$[0].total").value(25))
                .andExpect(jsonPath("$[1].total").value(14))
                .andExpect(jsonPath("$[2].firstName").value("Ana"))
                .andExpect(jsonPath("$[2].total").value(13))
                .andExpect(jsonPath("$[?(@.firstName == 'Fantasma')].total").value(0))
                .andExpect(jsonPath("$[?(@.firstName == 'Fantasma')].position").value(4))
                .andExpect(jsonPath("$[?(@.firstName == 'Zoe')].position").value(4))
                .andExpect(jsonPath("$[?(@.firstName == 'Ana')].matches").value(1));
    }

    @Test
    void theClubOpensAParticipantAndSeesEveryMatchOfTheirs() throws Exception {
        call(get("/api/v1/events/" + eventId + "/participants/" + fighters.get(0) + "/record"), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.standing.total").value(13))
                .andExpect(jsonPath("$.matches", hasSize(3)))
                .andExpect(
                        jsonPath("$.matches[?(@.rival == 'Bea Prueba')].points").value(3))
                .andExpect(jsonPath("$.matches[?(@.rival == 'Bea Prueba')].rivalPoints")
                        .value(15))
                .andExpect(
                        jsonPath("$.matches[?(@.rival == 'Bea Prueba')].status").value("FINISHED"))
                .andExpect(jsonPath("$.matches[?(@.rival == 'Bea Prueba')].asGhost")
                        .value(false));
        // The ghost's matches say so: they fight there and score nothing.
        call(get("/api/v1/events/" + eventId + "/participants/" + ghost + "/record"), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.matches[0].asGhost").value(true))
                .andExpect(jsonPath("$.standing.total").value(0));
        call(get("/api/v1/events/" + eventId + "/participants/" + fighters.get(0) + "/record"), "ayudante1")
                .andExpect(status().isForbidden());
        call(get("/api/v1/events/" + eventId + "/participants/" + java.util.UUID.randomUUID() + "/record"), "club1")
                .andExpect(status().isNotFound());
    }

    @Test
    void positionsCountWithinEachCategory() throws Exception {
        var younger = new Participant(eventId, clock.instant());
        younger.update("Lia", "Prueba", LocalDate.of(2027, 3, 1).minusYears(5), 110, true);
        participants.save(younger);

        // Lia scores nothing but is alone in her category: first there, not fifth of everyone.
        call(get("/api/v1/events/" + eventId + "/standings"), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.firstName == 'Lia')].position").value(1))
                .andExpect(jsonPath("$[?(@.firstName == 'Bea')].position").value(1))
                .andExpect(jsonPath("$[?(@.firstName == 'Zoe')].position").value(4));
    }

    @Test
    void aDisqualifiedFighterScoresNothingInThatMatch() throws Exception {
        var third = match(fighters.get(0), fighters.get(2));
        referee(third, "START", null, null);
        referee(third, "POINT", "RED", null);
        referee(third, "DISQUALIFICATION", "RED", "Conducta antideportiva");
        referee(third, "FINISH", null, null);

        call(get("/api/v1/events/" + eventId + "/standings"), "club1")
                .andExpect(jsonPath("$[?(@.firstName == 'Ana')].matchPoints").value(3))
                .andExpect(jsonPath("$[?(@.firstName == 'Ana')].matches").value(2))
                .andExpect(jsonPath("$[?(@.matches == 2 && @.firstName != 'Ana')].matchPoints")
                        .value(4 + 15));
        var matches = call(get("/api/v1/events/" + eventId + "/export/matches.csv"), "club1")
                .andReturn()
                .getResponse()
                .getContentAsString(StandardCharsets.UTF_8);
        assertThat(matches).contains(";Ana Prueba;;").contains(";0;15;");
        assertThat(matches).contains(";Descalificación de Ana Prueba;Terminado;Fantasma Prueba;");
    }

    @Test
    void csvExportsOpenInASpanishSpreadsheetAndNeutraliseFormulas() throws Exception {
        var standings = call(get("/api/v1/events/" + eventId + "/export/standings.csv"), "club1")
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(new MediaType("text", "csv")))
                .andExpect(header().string("Content-Disposition", "attachment; filename=\"clasificacion-fase.csv\""))
                .andReturn()
                .getResponse()
                .getContentAsString(StandardCharsets.UTF_8);
        assertThat(standings).startsWith(Csv.BOM + "Posición;Nombre;Apellidos;Edad el día del evento;Club;Categoría");
        assertThat(standings).contains("1;Bea;Prueba;9;;9-10;;10;15;25;1");
        assertThat(standings).contains("\"'=HYPERLINK(\"\"x\"\")\"");

        var matches = call(get("/api/v1/events/" + eventId + "/export/matches.csv"), "club1")
                .andReturn()
                .getResponse()
                .getContentAsString(StandardCharsets.UTF_8);
        assertThat(matches.lines()).hasSize(7);
        assertThat(matches)
                .contains("1;9-10;1;1;Ana Prueba;;Bea Prueba;;3;15;Bea Prueba;Llegó a 15 puntos;Terminado;"
                        + "Fantasma Prueba;10/03/2027;");

        var timeline = call(get("/api/v1/events/" + eventId + "/export/timeline.csv"), "club1")
                .andReturn()
                .getResponse()
                .getContentAsString(StandardCharsets.UTF_8);
        assertThat(timeline).contains(";Parar reloj;;;;Automático;;No");
    }

    @Test
    void onlyTheClubSeesTheStandings() throws Exception {
        call(get("/api/v1/events/" + eventId + "/standings"), "ayudante1").andExpect(status().isForbidden());
        call(get("/api/v1/events/" + eventId + "/export/matches.csv"), "arbitro1")
                .andExpect(status().isForbidden());
    }

    private UUID participant(String firstName) {
        var participant = new Participant(eventId, clock.instant());
        participant.update(firstName, "Prueba", LocalDate.of(2027, 3, 1).minusYears(9), 130, true);
        return participants.save(participant).getId();
    }

    private UUID match(UUID red, UUID blue) {
        return jdbc.sql("select id from fight_match where red_participant_id = ? and blue_participant_id = ?")
                .params(red, blue)
                .query(UUID.class)
                .single();
    }

    private void referee(UUID match, String type, String side, String reason) throws Exception {
        call(
                        post("/api/v1/matches/" + match + "/events").content("""
                                {"type":"%s","side":%s,"reason":%s,"knownEvents":%d}""".formatted(
                                        type,
                                        side == null ? "null" : "\"" + side + "\"",
                                        reason == null ? "null" : "\"" + reason + "\"",
                                        knownEvents(match))),
                        "arbitro1")
                .andExpect(status().isOk());
    }
}
