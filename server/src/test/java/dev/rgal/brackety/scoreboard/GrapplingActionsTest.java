package dev.rgal.brackety.scoreboard;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.event.ScoringRules;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.ResultActions;
import tools.jackson.databind.json.JsonMapper;

/**
 * A grappling event's actions through the API, the device's rescue file and the hall's results (docs/producto/
 * grappling.md, G2b): each point keeps its value, and a submission or the extra time names the winner.
 */
class GrapplingActionsTest extends ScoreboardApiTest {

    @Autowired
    JsonMapper json;

    UUID match;

    @BeforeEach
    void grappling() {
        jdbc.sql("update modality set scoring = ?::jsonb where event_id = ?")
                .params(json.writeValueAsString(ScoringRules.GRAPPLING), eventId)
                .update();
        jdbc.sql("update modality_rules set points_limit = 0 where modality_id in"
                        + " (select id from modality where event_id = ?)")
                .param(eventId)
                .update();
        match = match(young, 0, 1);
    }

    @Test
    void eachPointKeepsItsValueAndASubmissionEndsTheMatch() throws Exception {
        act("START", null, null).andExpect(status().isOk());
        act("POINT", "RED", 4).andExpect(status().isOk());
        act("POINT", "BLUE", 2).andExpect(status().isOk());
        act("SUBMISSION", "BLUE", null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.red.points").value(4))
                .andExpect(jsonPath("$.blue.points").value(2))
                .andExpect(jsonPath("$.endReason").value("SUBMISSION"))
                // The winner by the rules, though Blue has fewer points.
                .andExpect(jsonPath("$.winner").value("BLUE"))
                .andExpect(jsonPath("$.needsExtraTime").value(false))
                .andExpect(jsonPath("$.timeline[1].points").value(4))
                .andExpect(jsonPath("$.timeline[2].points").value(2));
        act("FINISH", null, null).andExpect(status().isOk());
    }

    @Test
    void aValueNoButtonHasIsRefused() throws Exception {
        act("START", null, null).andExpect(status().isOk());

        act("POINT", "RED", 5).andExpect(status().isConflict());
        act("SUBMISSION", null, null).andExpect(status().isBadRequest());
    }

    @Test
    void aRemovedPointTakesOffItsValue() throws Exception {
        act("START", null, null).andExpect(status().isOk());
        act("POINT", "RED", 4).andExpect(status().isOk());

        act("POINT_REMOVED", "RED", 4)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.red.points").value(0));
    }

    @Test
    void theRescueFileCarriesEachPointsValue() throws Exception {
        var referee = accountId("arbitro1");
        var csv = "﻿brackety-offline-ops;3\r\nopId;matchId;type;side;reason;at;knownEvents;actor;deltaMs;points\r\n"
                + "%s;%s;START;;;2027-03-10T09:00:00Z;0;%s;;\r\n".formatted(UUID.randomUUID(), match, referee)
                + "%s;%s;POINT;RED;;2027-03-10T09:00:10Z;1;%s;;3\r\n".formatted(UUID.randomUUID(), match, referee);
        var token = auth.login("club1", "club1", "127.0.0.1").accessToken();

        mvc.perform(post("/api/v1/events/" + eventId + "/offline-ops/import")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(new MediaType("text", "csv"))
                        .content(csv.getBytes(StandardCharsets.UTF_8)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.applied").value(2));

        call(get(path(match)), "club1")
                .andExpect(jsonPath("$.red.points").value(3))
                .andExpect(jsonPath("$.timeline[1].points").value(3));
    }

    // The hall's results reach the Pi with each point's value and each clock adjustment (before, the adjustment
    // arrived as 0).
    @Test
    void theHallsResultsKeepPointsAndClockAdjustments() throws Exception {
        act("START", null, null).andExpect(status().isOk());
        clock.advance(java.time.Duration.ofSeconds(20));
        act("POINT", "RED", 4).andExpect(status().isOk());
        act("STOP", null, null).andExpect(status().isOk());
        call(post(path(match) + "/events").content("""
                                {"type":"CLOCK_ADJUST","knownEvents":3,"deltaMs":-10000}"""), "arbitro1").andExpect(status().isOk());
        var zip = call(get("/api/v1/events/" + eventId + "/export/full"), "club1")
                .andReturn()
                .getResponse()
                .getContentAsByteArray();
        jdbc.sql("delete from fight_group where event_id = ?").param(eventId).update();
        jdbc.sql("update event set started_at = null where id = ?")
                .param(eventId)
                .update();
        var token = auth.login("club1", "club1", "127.0.0.1").accessToken();

        mvc.perform(post("/api/v1/events/" + eventId + "/import/results")
                        .param("dryRun", "false")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_OCTET_STREAM)
                        .content(zip))
                .andExpect(status().isOk());

        assertThat(jdbc.sql("select points from match_event where type = 'POINT'")
                        .query(Integer.class)
                        .single())
                .isEqualTo(4);
        assertThat(jdbc.sql("select delta_ms from match_event where type = 'CLOCK_ADJUST'")
                        .query(Long.class)
                        .single())
                .isEqualTo(-10_000);
    }

    private ResultActions act(String type, String side, Integer points) throws Exception {
        var match = this.match;
        return call(
                post(path(match) + "/events").content("""
                        {"type":"%s","side":%s,"points":%s,"knownEvents":%d}""".formatted(
                                type,
                                side == null ? "null" : "\"" + side + "\"",
                                points == null ? "null" : points,
                                knownEvents(match))),
                "arbitro1");
    }
}
