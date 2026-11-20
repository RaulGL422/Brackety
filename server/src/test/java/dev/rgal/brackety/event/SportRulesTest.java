package dev.rgal.brackety.event;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

/** A sport's rules are data of the event (docs/producto/grappling.md, G2a): what each event keeps and sends. */
class SportRulesTest extends EventApiTest {

    @Autowired
    ParticipantRepository participants;

    @Test
    void theTamboEventKeepsTamboRules() throws Exception {
        call(get("/api/v1/events/" + eventId + "/settings"), "club1")
                .andExpect(jsonPath("$.discipline").value("TAMBO"))
                .andExpect(jsonPath("$.scoring.actions", hasSize(1)))
                .andExpect(jsonPath("$.scoring.warningsPerRivalPoint").value(2))
                .andExpect(jsonPath("$.scoring.submissions").value(false));
    }

    // A tambo phase hands nothing of tambo's to a grappling one: rules, length and warning reasons are grappling's.
    @Test
    void aGrapplingPhaseStartsFromGrapplingRules() throws Exception {
        var body = call(post("/api/v1/events/" + eventId + "/league/phases").content("""
                        {"name":"Open de grappling","date":"2027-04-10","discipline":"GRAPPLING",
                         "attendancePoints":0}"""), "club1")
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        var grappling = UUID.fromString(JsonPath.read(body, "$.eventId"));

        call(get("/api/v1/events/" + grappling + "/settings"), "club1")
                .andExpect(jsonPath("$.discipline").value("GRAPPLING"))
                .andExpect(jsonPath("$.matchSeconds").value(300))
                .andExpect(jsonPath("$.pointsLimit").value(0))
                .andExpect(jsonPath("$.scoring.actions", hasSize(4)))
                .andExpect(jsonPath("$.scoring.actions[3].value").value(4))
                .andExpect(jsonPath("$.scoring.warningsToDisqualify").value(4))
                .andExpect(jsonPath("$.scoring.superiorityGap").value(15))
                .andExpect(jsonPath("$.scoring.submissions").value(true))
                .andExpect(jsonPath("$.warningReasons.sport[0]").value("Pasividad"));
    }

    // Grappling: U15 fight 4 minutes in an event of 5.
    @Test
    void aCategoryWithItsOwnLengthGivesItToItsMatches() throws Exception {
        call(put("/api/v1/events/" + eventId + "/categories").content("""
                        {"categories":[{"name":"U15 M -46 kg","minAge":14,"maxAge":15,"format":"INDIVIDUAL",
                          "groupSize":4,"matchSeconds":240}]}"""), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].matchSeconds").value(240));
        call(get("/api/v1/events/" + eventId + "/settings"), "club1")
                .andExpect(jsonPath("$.categories[0].matchSeconds").value(240));

        var category = jdbc.sql("select id from event_category where event_id = ?")
                .param(eventId)
                .query(UUID.class)
                .single();
        var people = new ArrayList<UUID>();
        for (var name : new String[] {"Ana", "Bea", "Carla", "Dani"}) {
            people.add(participant(name, 14));
        }
        call(
                        post("/api/v1/events/" + eventId + "/groups").content("""
                                {"categoryId":"%s","groups":[{"participantIds":[%s]}]}""".formatted(
                                category,
                                people.stream().map(id -> "\"" + id + "\"").collect(Collectors.joining(",")))),
                        "ayudante1")
                .andExpect(status().isCreated());
        var match = jdbc.sql("select id from fight_match where event_id = ? limit 1")
                .param(eventId)
                .query(UUID.class)
                .single();

        call(get("/api/v1/matches/" + match), "club1")
                .andExpect(jsonPath("$.lengthSeconds").value(240))
                .andExpect(jsonPath("$.remainingMs").value(240_000))
                .andExpect(jsonPath("$.scoring.actions[0].label").value("Punto"));
    }

    private UUID participant(String firstName, int age) {
        var participant = new Participant(eventId, clock.instant());
        participant.update(firstName, "Prueba", LocalDate.of(2027, 3, 1).minusYears(age), 160, true);
        return participants.save(participant).getId();
    }
}
