package dev.rgal.brackety.league;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasItem;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.event.EventApiTest;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** A standalone event (docs/producto/grappling.md, G4): a league of one phase with its sport's rules and its mats. */
class NewEventTest extends EventApiTest {

    @Test
    void anAccountCreatesAGrapplingEventAndRunsIt() throws Exception {
        var body = call(post("/api/v1/events").content("""
                        {"name":" Open de grappling ","date":"2027-05-08","discipline":"GRAPPLING","mats":3}"""), "arbitro1")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.name").value("Open de grappling"))
                .andExpect(jsonPath("$.number").value(1))
                .andReturn()
                .getResponse()
                .getContentAsString();
        var event = UUID.fromString(JsonPath.read(body, "$.eventId"));

        // Its creator is its club, whatever they are in other events.
        call(get("/api/v1/events"), "arbitro1")
                .andExpect(
                        jsonPath("$[?(@.id == '%s')].roles[0]".formatted(event)).value(hasItem("CLUB")))
                .andExpect(jsonPath("$[?(@.id == '%s')].phaseNumber".formatted(event))
                        .value(hasItem(1)));
        call(get("/api/v1/events/" + event + "/settings"), "arbitro1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.discipline").value("GRAPPLING"))
                .andExpect(jsonPath("$.attendancePoints").value(0))
                .andExpect(jsonPath("$.scoring.finishes[0]").value("Sumisión"));
        assertThat(jdbc.sql("select count(*) from mat where event_id = ? and referee_account_id is null")
                        .param(event)
                        .query(Integer.class)
                        .single())
                .isEqualTo(3);
        // Nobody else sees it, nor that it exists.
        call(get("/api/v1/events/" + event + "/settings"), "club1").andExpect(status().isNotFound());
    }

    @Test
    void aSportWithoutAScoreboardOrNoMatsIsRefused() throws Exception {
        call(post("/api/v1/events").content("""
                        {"name":"Suelo","date":"2027-05-08","discipline":"GROUND","mats":1}"""), "club1").andExpect(status().isBadRequest());
        call(post("/api/v1/events").content("""
                        {"name":"Sin tapices","date":"2027-05-08","discipline":"TAMBO","mats":0}"""), "club1").andExpect(status().isBadRequest());
    }

    @Test
    void theSportsToPickFromSayWhichHaveAScoreboard() throws Exception {
        call(get("/api/v1/events/disciplines"), "club1")
                .andExpect(
                        jsonPath("$[?(@.discipline == 'GRAPPLING')].available").value(hasItem(true)))
                .andExpect(jsonPath("$[?(@.discipline == 'GROUND')].available").value(hasItem(false)));
    }
}
