package dev.rgal.brackety.scoreboard;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Duration;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.ResultActions;

class ScoreboardControllerTest extends ScoreboardApiTest {

    @Test
    void theClockRunsOnTheServerAndTheMatchFinishesWhenTheTimeIsOver() throws Exception {
        var match = match(young, 0, 1);

        event(match, "START")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.running").value(true));
        clock.advance(Duration.ofSeconds(30));
        event(match, "POINT", "RED");
        event(match, "POINT", "RED");
        event(match, "STOP")
                .andExpect(jsonPath("$.running").value(false))
                .andExpect(jsonPath("$.remainingMs").value(90_000))
                .andExpect(jsonPath("$.red.points").value(2));
        event(match, "FINISH").andExpect(status().isConflict());

        event(match, "START");
        clock.advance(Duration.ofMinutes(5));
        call(get(path(match)), "arbitro1")
                .andExpect(jsonPath("$.remainingMs").value(0))
                .andExpect(jsonPath("$.running").value(false))
                .andExpect(jsonPath("$.endReason").value("TIME"));
        event(match, "POINT", "BLUE").andExpect(status().isConflict());
        event(match, "FINISH")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("FINISHED"));
        event(match, "UNDO").andExpect(status().isConflict());
        call(get("/api/v1/mats/" + matOf(match) + "/board"), "arbitro1")
                .andExpect(jsonPath("$.recommendedMatchId")
                        .value(match(young, 2, 3).toString()));

        call(get(path(match)), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.timeline", hasSize(6)))
                .andExpect(jsonPath("$.timeline[1].type").value("POINT"))
                .andExpect(jsonPath("$.timeline[1].actor").value("arbitro1"))
                .andExpect(jsonPath("$.timeline[1].clockMs").value(30_000));
    }

    @Test
    void fifteenPointsStopTheClockAndUndoingKeepsItStopped() throws Exception {
        var match = match(young, 0, 1);
        event(match, "START");
        for (int i = 0; i < 14; i++) {
            event(match, "POINT", "BLUE");
        }

        event(match, "POINT", "BLUE")
                .andExpect(jsonPath("$.endReason").value("POINTS"))
                .andExpect(jsonPath("$.running").value(false))
                .andExpect(jsonPath("$.timeline[16].type").value("STOP"))
                .andExpect(jsonPath("$.timeline[16].automatic").value(true));
        event(match, "UNDO")
                .andExpect(jsonPath("$.blue.points").value(14))
                .andExpect(jsonPath("$.endReason").doesNotExist())
                .andExpect(jsonPath("$.running").value(false))
                .andExpect(jsonPath("$.timeline[15].undone").value(true));
        event(match, "START").andExpect(jsonPath("$.running").value(true));
    }

    @Test
    void warningsNeedAReasonAndTheOneHandWarningIsOnlyForTheYoungest() throws Exception {
        var match = match(young, 0, 1);
        event(match, "START");

        event(match, "WARNING", "RED").andExpect(status().isBadRequest());
        event(match, "WARNING", "RED", "Pique")
                .andExpect(jsonPath("$.red.warnings").value(1));
        event(match, "ONE_HAND_WARNING", "RED", "Una mano");
        event(match, "ONE_HAND_WARNING", "RED", "Una mano")
                .andExpect(jsonPath("$.red.oneHandRule").value(true))
                .andExpect(jsonPath("$.red.oneHandWarnings").value(2))
                .andExpect(jsonPath("$.blue.points").value(1))
                .andExpect(jsonPath("$.timeline[3].gaveRivalPoint").value(true));
        event(match, "DISQUALIFICATION", "RED", "Conducta antideportiva")
                .andExpect(jsonPath("$.endReason").value("DISQUALIFICATION"))
                .andExpect(jsonPath("$.red.disqualified").value(true))
                .andExpect(jsonPath("$.running").value(false));

        var olderMatch = match(older, 0, 1);
        call(post(path(olderMatch) + "/events").content(body("START", null, null)), "arbitro2");
        call(post(path(olderMatch) + "/events").content(body("ONE_HAND_WARNING", "RED", "Una mano")), "arbitro2")
                .andExpect(status().isBadRequest());
    }

    @Test
    void oneMatchAtATimePerMatAndAFighterCannotBeInTwo() throws Exception {
        event(match(young, 0, 1), "START");

        event(match(young, 2, 3), "START").andExpect(status().isConflict());
    }

    @Test
    void onlyTheMatsRefereeWritesAndTheClubOnlyReads() throws Exception {
        var match = match(young, 0, 1);

        call(post(path(match) + "/events").content(body("START", null, null)), "arbitro2")
                .andExpect(status().isForbidden());
        call(post(path(match) + "/events").content(body("START", null, null)), "club1")
                .andExpect(status().isForbidden());
        call(get(path(match)), "club1").andExpect(status().isOk());
        call(get(path(match)), "ayudante1").andExpect(status().isForbidden());
        call(get(path(match)), outsider(), PASSWORD).andExpect(status().isNotFound());
    }

    private ResultActions event(UUID match, String type) throws Exception {
        return event(match, type, null, null);
    }

    private ResultActions event(UUID match, String type, String side) throws Exception {
        return event(match, type, side, null);
    }

    private ResultActions event(UUID match, String type, String side, String reason) throws Exception {
        return call(post(path(match) + "/events").content(body(type, side, reason)), "arbitro1");
    }

    private static String body(String type, String side, String reason) {
        return """
                {"type":"%s","side":%s,"reason":%s}""".formatted(type, quote(side), quote(reason));
    }

    private static String quote(String value) {
        return value == null ? "null" : "\"" + value + "\"";
    }
}
