package dev.rgal.brackety.league;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
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
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

// The demo event (2027-03-10) is phase 1 of "Liga Yoseikan 2027".
class LeagueControllerTest extends EventApiTest {

    @Autowired
    ParticipantRepository participants;

    @Test
    void theDemoEventIsPhaseOneOfALeagueWithTheDefaultPodium() throws Exception {
        call(get(league(eventId)), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Liga Yoseikan 2027"))
                .andExpect(jsonPath("$.podium.firsts").value(2))
                .andExpect(jsonPath("$.podium.seconds").value(2))
                .andExpect(jsonPath("$.podium.thirds").value(3))
                .andExpect(jsonPath("$.phases", hasSize(1)))
                .andExpect(jsonPath("$.phases[0].number").value(1))
                .andExpect(jsonPath("$.disciplines[0].discipline").value("TAMBO"))
                .andExpect(jsonPath("$.disciplines[0].available").value(true))
                .andExpect(jsonPath("$.disciplines[1].available").value(false));
    }

    @Test
    void aNewPhaseCopiesTheConfigurationButNotTheEntries() throws Exception {
        participant(eventId, "Ana", 30);

        var phase2 = newPhase();

        call(get("/api/v1/events/" + phase2 + "/settings"), "club1")
                .andExpect(jsonPath("$.name").value("Liga Yoseikan 2027 · Fase 2 · Tambo"))
                .andExpect(jsonPath("$.date").value("2027-04-10"))
                .andExpect(jsonPath("$.phaseNumber").value(2))
                .andExpect(jsonPath("$.attendancePoints").value(12))
                .andExpect(jsonPath("$.mats", hasSize(5)))
                .andExpect(jsonPath("$.mats[0].refereeId")
                        .value(accountId("arbitro1").toString()))
                .andExpect(jsonPath("$.categories", hasSize(9)))
                .andExpect(jsonPath("$.organizations", hasSize(2)));
        call(get("/api/v1/events/" + phase2 + "/participants"), "club1").andExpect(jsonPath("$", hasSize(0)));
        // The staff comes along: the referee sees the new phase among their events with the same mat.
        call(get("/api/v1/events"), "arbitro1")
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].phaseNumber").value(2))
                .andExpect(jsonPath("$[0].matNumber").value(1));
        call(get(league(phase2)), "club1").andExpect(jsonPath("$.phases", hasSize(2)));
    }

    @Test
    void aDisciplineWithoutScoreboardCannotBeAPhaseYet() throws Exception {
        call(post(league(eventId) + "/phases").content("""
                        {"name":"Fase 2","date":"2027-04-10","discipline":"GROUND","attendancePoints":10}"""), "club1").andExpect(status().isBadRequest());
        call(post(league(eventId) + "/phases").content("""
                        {"name":"Fase 2","date":"2027-04-10","discipline":"TAMBO","attendancePoints":10}"""), "ayudante1").andExpect(status().isForbidden());
    }

    @Test
    void theClubReentersPeopleOfThePreviousPhaseKeepingTheirPerson() throws Exception {
        var child = participant(eventId, "Leo", 9);
        participant(eventId, "Ana", 30);
        var phase2 = newPhase();

        call(get(league(phase2) + "/candidates"), "club1")
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].firstName").value("Ana"))
                .andExpect(jsonPath("$[0].organizationName").value("Club Demo Yoseikan"))
                .andExpect(jsonPath("$[1].categoryName").value("9-10"))
                .andExpect(jsonPath("$[1].lastPhase").value(1));
        var everyone = "[\"%s\",\"%s\"]"
                .formatted(
                        person(child),
                        person(participants.findAll().stream()
                                .filter(p -> p.getFirstName().equals("Ana"))
                                .findFirst()
                                .orElseThrow()
                                .getId()));
        // A minor among them: the guardians must agree again for this phase.
        call(post(league(phase2) + "/reenrol").content("""
                        {"personIds":%s,"guardianConsent":false}""".formatted(everyone)), "club1")
                .andExpect(status().isBadRequest());
        call(post(league(phase2) + "/reenrol").content("""
                        {"personIds":%s,"guardianConsent":true}""".formatted(everyone)), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.added").value(2));

        call(get(league(phase2) + "/candidates"), "club1").andExpect(jsonPath("$", hasSize(0)));
        call(get("/api/v1/events/" + phase2 + "/participants"), "club1")
                .andExpect(jsonPath("$[1].personId").value(person(child).toString()))
                .andExpect(jsonPath("$[0].organizationName").value("Club Demo Yoseikan"));
        call(post(league(phase2) + "/reenrol").content("""
                        {"personIds":["%s"],"guardianConsent":true}""".formatted(person(child))), "club1")
                .andExpect(status().isBadRequest());
    }

    @Test
    void pointsAddUpAcrossPhasesWithMedalsByThePodium() throws Exception {
        var kids = new ArrayList<UUID>();
        for (var name : List.of("Ana", "Bea", "Cris", "Dani")) {
            kids.add(participant(eventId, name, 9));
        }
        group(eventId, kids);
        var first = match(kids.get(0), kids.get(1));
        act(first, "START", null);
        act(first, "POINT", "RED");
        act(first, "POINT", "RED");
        act(first, "POINT", "BLUE");
        clock.advance(Duration.ofMinutes(3));
        act(first, "FINISH", null);
        call(put(league(eventId)).content("""
                        {"name":"Liga Yoseikan 2027","podium":{"firsts":2,"seconds":2,"thirds":3},
                         "categoryPodiums":[{"categoryName":"9-10","podium":{"firsts":1,"seconds":1,"thirds":1}}]}"""), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.categoryPodiums[0].podium.firsts").value(1));

        var phase2 = newPhase();
        call(post(league(phase2) + "/reenrol").content("""
                        {"personIds":["%s"],"guardianConsent":true}""".formatted(person(kids.get(1)))), "club1")
                .andExpect(status().isOk());

        // Ana 10+2, Bea 10+1 (+12 in phase 2 without groups: 0), Cris and Dani 10.
        call(get(league(phase2) + "/standings"), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.phases", hasSize(2)))
                .andExpect(jsonPath("$.rows", hasSize(4)))
                .andExpect(jsonPath("$.rows[0].firstName").value("Ana"))
                .andExpect(jsonPath("$.rows[0].total").value(12))
                .andExpect(jsonPath("$.rows[0].medal").value(1))
                .andExpect(jsonPath("$.rows[0].phases[1]").value(nullValue()))
                .andExpect(jsonPath("$.rows[1].firstName").value("Bea"))
                .andExpect(jsonPath("$.rows[1].phases[1].attendancePoints").value(0))
                .andExpect(jsonPath("$.rows[1].medal").value(2))
                .andExpect(jsonPath("$.rows[2].position").value(3))
                .andExpect(jsonPath("$.rows[3].position").value(3))
                .andExpect(jsonPath("$.rows[2].medal").value(3))
                .andExpect(jsonPath("$.rows[3].medal").value(3));

        var csv = call(get("/api/v1/events/" + phase2 + "/export/league-standings.csv"), "club1")
                .andReturn()
                .getResponse()
                .getContentAsString(StandardCharsets.UTF_8);
        assertThat(csv).contains("Categoría;Posición;Medalla;Nombre;Apellidos;Club;Fase 1: asistencia");
        assertThat(csv).contains("9-10;1;Oro (1.º);Ana;Prueba;Club Demo Yoseikan;10;2;12;No inscrito;;;12");
    }

    @Test
    void medalsGoByPositionAndTiesShareThem() {
        var podium = new Podium(2, 2, 3);
        assertThat(List.of(1, 1, 3, 4, 5, 7, 8).stream()
                        .map(p -> podium.medal(p, 10))
                        .toList())
                .containsExactly(1, 1, 2, 2, 3, 3, null);
        assertThat(podium.medal(1, 0)).isNull();
        assertThat(new Podium(0, 0, 1).medal(1, 5)).isEqualTo(3);
    }

    private UUID newPhase() throws Exception {
        var body = call(post(league(eventId) + "/phases").content("""
                        {"name":"Liga Yoseikan 2027 · Fase 2 · Tambo","date":"2027-04-10","discipline":"TAMBO",
                         "attendancePoints":12}"""), "club1")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.number").value(2))
                .andReturn()
                .getResponse()
                .getContentAsString();
        return UUID.fromString(JsonPath.read(body, "$.eventId"));
    }

    private UUID participant(UUID event, String firstName, int age) {
        var organization = jdbc.sql("select id from event_organization where event_id = ? order by name limit 1")
                .param(event)
                .query(UUID.class)
                .single();
        var participant = new Participant(event, clock.instant());
        participant.update(firstName, "Prueba", LocalDate.of(2027, 3, 1).minusYears(age), 130, true);
        participant.setOrganizationId(organization);
        return participants.save(participant).getId();
    }

    private UUID person(UUID participantId) {
        return participants.findById(participantId).orElseThrow().getPersonId();
    }

    private void group(UUID event, List<UUID> members) throws Exception {
        var categoryId = jdbc.sql("select id from event_category where event_id = ? and name = '9-10'")
                .param(event)
                .query(UUID.class)
                .single();
        var ids = members.stream().map(id -> "\"" + id + "\"").collect(Collectors.joining(","));
        call(post("/api/v1/events/" + event + "/groups").content("""
                                {"categoryId":"%s","groups":[{"participantIds":[%s]}]}""".formatted(categoryId, ids)), "ayudante1")
                .andExpect(status().isCreated());
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

    private static String league(UUID event) {
        return "/api/v1/events/" + event + "/league";
    }
}
