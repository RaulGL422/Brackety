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
    void aDisqualifiedFighterScoresNothingInThatMatch() throws Exception {
        var third = match(fighters.get(0), fighters.get(2));
        referee(third, "START", null, null);
        referee(third, "POINT", "RED", null);
        referee(third, "DISQUALIFICATION", "RED", "Conducta antideportiva");
        referee(third, "FINISH", null, null);

        call(get("/api/v1/events/" + eventId + "/standings"), "club1")
                .andExpect(jsonPath("$[?(@.firstName == 'Ana')].matchPoints").value(3))
                .andExpect(jsonPath("$[?(@.firstName == 'Ana')].matches").value(2));
    }

    @Test
    void csvExportsOpenInASpanishSpreadsheetAndNeutraliseFormulas() throws Exception {
        var standings = call(get("/api/v1/events/" + eventId + "/export/standings.csv"), "club1")
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(new MediaType("text", "csv")))
                .andExpect(header().string("Content-Disposition", "attachment; filename=\"clasificacion.csv\""))
                .andReturn()
                .getResponse()
                .getContentAsString(StandardCharsets.UTF_8);
        assertThat(standings).startsWith(Csv.BOM + "Posición;Nombre;Apellidos;Edad;Categoría");
        assertThat(standings).contains("1;Bea;Prueba;9;9-10;10;15;25;1");
        assertThat(standings).contains("\"'=HYPERLINK(\"\"x\"\")\"");

        var matches = call(get("/api/v1/events/" + eventId + "/export/matches.csv"), "club1")
                .andReturn()
                .getResponse()
                .getContentAsString(StandardCharsets.UTF_8);
        assertThat(matches.lines()).hasSize(7);
        assertThat(matches).contains("1;1;9-10;1;Ana Prueba;Bea Prueba;3;15;Fantasma Prueba;;finalizado;");

        var timeline = call(get("/api/v1/events/" + eventId + "/export/timeline.csv"), "club1")
                .andReturn()
                .getResponse()
                .getContentAsString(StandardCharsets.UTF_8);
        assertThat(timeline).contains(";STOP;;;;automático;");
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
                                {"type":"%s","side":%s,"reason":%s}""".formatted(
                                        type,
                                        side == null ? "null" : "\"" + side + "\"",
                                        reason == null ? "null" : "\"" + reason + "\"")),
                        "arbitro1")
                .andExpect(status().isOk());
    }
}
