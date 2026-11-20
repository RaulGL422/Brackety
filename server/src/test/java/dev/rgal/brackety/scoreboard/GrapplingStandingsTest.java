package dev.rgal.brackety.scoreboard;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.event.ScoringRules;
import java.time.Duration;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import tools.jackson.databind.json.JsonMapper;

/**
 * A grappling group of four plays its six matches through the scoreboard, each ending another way, and Puntuaciones
 * ranks it as the FELODA does (art. 8 and 39): wins first, then classification points.
 */
class GrapplingStandingsTest extends ScoreboardApiTest {

    @Autowired
    JsonMapper json;

    UUID ana;
    UUID bea;
    UUID carla;
    UUID dani;

    @BeforeEach
    void grappling() {
        jdbc.sql("update modality set scoring = ?::jsonb where event_id = ?")
                .params(json.writeValueAsString(ScoringRules.GRAPPLING), eventId)
                .update();
        jdbc.sql("update modality_rules set points_limit = 0 where modality_id in"
                        + " (select id from modality where event_id = ?)")
                .param(eventId)
                .update();
        ana = young.get(0);
        bea = young.get(1);
        carla = young.get(2);
        dani = young.get(3);
    }

    @Test
    void theGroupRanksByWinsThenClassificationPoints() throws Exception {
        // Ana: submission over Bea (5) and superiority over Carla, who scored (4). Dani: decision over Ana, who scored
        // (3, Ana 1) and extra time over Bea (2). Bea: decision over Carla, who did not score (3). Carla: Dani's four
        // warnings (3).
        play(ana, bea, ana, "SUBMISSION");
        play(ana, carla, ana, "SUPERIORITY");
        play(ana, dani, dani, "TIME");
        play(bea, carla, bea, "TIME");
        play(bea, dani, dani, "EXTRA_TIME");
        play(carla, dani, carla, "WARNINGS");

        call(get("/api/v1/events/" + eventId + "/standings"), "club1")
                .andExpect(jsonPath("$[?(@.participantId == '%s')].wins".formatted(ana))
                        .value(2))
                .andExpect(jsonPath("$[?(@.participantId == '%s')].classificationPoints".formatted(ana))
                        .value(10))
                .andExpect(jsonPath("$[?(@.participantId == '%s')].position".formatted(ana))
                        .value(1))
                .andExpect(jsonPath("$[?(@.participantId == '%s')].classificationPoints".formatted(dani))
                        .value(5))
                .andExpect(jsonPath("$[?(@.participantId == '%s')].position".formatted(dani))
                        .value(2))
                .andExpect(jsonPath("$[?(@.participantId == '%s')].classificationPoints".formatted(carla))
                        .value(4))
                .andExpect(jsonPath("$[?(@.participantId == '%s')].position".formatted(carla))
                        .value(3))
                .andExpect(jsonPath("$[?(@.participantId == '%s')].classificationPoints".formatted(bea))
                        .value(3))
                .andExpect(jsonPath("$[?(@.participantId == '%s')].position".formatted(bea))
                        .value(4));
    }

    @Test
    void tamboKeepsRankingByPoints() throws Exception {
        jdbc.sql("update modality set scoring = ?::jsonb where event_id = ?")
                .params(json.writeValueAsString(ScoringRules.TAMBO), eventId)
                .update();

        call(get("/api/v1/events/" + eventId + "/standings"), "club1")
                .andExpect(jsonPath("$[0].wins").doesNotExist())
                .andExpect(jsonPath("$[0].classificationPoints").doesNotExist());
    }

    // The match between a and b, whichever corner each is in, ended as {@code end} with {@code winner} winning.
    private void play(UUID a, UUID b, UUID winner, String end) throws Exception {
        var match = jdbc.sql("select id from fight_match where (red_participant_id = ? and blue_participant_id = ?)"
                        + " or (red_participant_id = ? and blue_participant_id = ?)")
                .params(a, b, b, a)
                .query(UUID.class)
                .single();
        var red = jdbc.sql("select red_participant_id from fight_match where id = ?")
                .param(match)
                .query(UUID.class)
                .single();
        var winnerSide = winner.equals(red) ? "RED" : "BLUE";
        var loserSide = winnerSide.equals("RED") ? "BLUE" : "RED";
        act(match, "START", null, null);
        switch (end) {
            case "SUBMISSION" -> act(match, "SUBMISSION", winnerSide, null);
            case "SUPERIORITY" -> {
                act(match, "POINT", loserSide, 2);
                for (int i = 0; i < 4; i++) {
                    act(match, "POINT", winnerSide, 4);
                }
                act(match, "POINT", winnerSide, 1);
            }
            case "TIME" -> {
                // Ana scores against Dani; Carla scores nothing against Bea.
                if (winner.equals(dani)) {
                    act(match, "POINT", loserSide, 1);
                }
                act(match, "POINT", winnerSide, 3);
                clock.advance(Duration.ofMinutes(5));
            }
            case "EXTRA_TIME" -> {
                act(match, "POINT", winnerSide, 2);
                act(match, "POINT", loserSide, 2);
                clock.advance(Duration.ofMinutes(5));
                act(match, "EXTRA_TIME", winnerSide, null);
            }
            case "WARNINGS" -> {
                for (int i = 0; i < 4; i++) {
                    act(match, "WARNING", loserSide, null);
                }
            }
            default -> throw new IllegalArgumentException(end);
        }
        act(match, "FINISH", null, null);
        clock.advance(Duration.ofMinutes(10));
    }

    private void act(UUID match, String type, String side, Integer points) throws Exception {
        var reason = type.equals("WARNING") ? "\"Pasividad\"" : "null";
        call(
                        post(path(match) + "/events").content("""
                                {"type":"%s","side":%s,"points":%s,"reason":%s,"knownEvents":%d}""".formatted(
                                        type,
                                        side == null ? "null" : "\"" + side + "\"",
                                        points == null ? "null" : points,
                                        reason,
                                        knownEvents(match))),
                        "arbitro1")
                .andExpect(status().isOk());
    }
}
