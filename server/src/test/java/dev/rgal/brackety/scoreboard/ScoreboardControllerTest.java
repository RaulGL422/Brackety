package dev.rgal.brackety.scoreboard;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Duration;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
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
                .andExpect(jsonPath("$.remainingMs").value(150_000))
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
    void nothingIsScoredBeforeStart() throws Exception {
        var match = match(young, 0, 1);

        event(match, "POINT", "RED")
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.detail").value("The match has not started: press Start first."));
        event(match, "WARNING", "BLUE", "Salida").andExpect(status().isConflict());
        event(match, "DISQUALIFICATION", "BLUE", "Conducta").andExpect(status().isConflict());
        event(match, "START");
        event(match, "STOP");
        event(match, "POINT", "RED")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.red.points").value(1));
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
        call(post(path(olderMatch) + "/events").content(body("START", null, null, 0)), "arbitro2");
        call(post(path(olderMatch) + "/events").content(body("ONE_HAND_WARNING", "RED", "Una mano", 1)), "arbitro2")
                .andExpect(status().isBadRequest());
    }

    @Test
    void twoTabsPressingAtOnceCountOnce() throws Exception {
        var match = match(young, 0, 1);
        event(match, "START");
        var seen = knownEvents(match);

        call(post(path(match) + "/events").content(body("POINT", "RED", null, seen)), "arbitro1")
                .andExpect(status().isOk());
        call(post(path(match) + "/events").content(body("POINT", "RED", null, seen)), "arbitro1")
                .andExpect(status().isConflict())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.code").value("MATCH_STALE"));

        call(get(path(match)), "arbitro1")
                .andExpect(jsonPath("$.red.points").value(1))
                .andExpect(jsonPath("$.review").doesNotExist());
    }

    @Test
    void withoutKnownEventsTheActionIsRefused() throws Exception {
        call(post(path(match(young, 0, 1)) + "/events").content("""
                                {"type":"START"}"""), "arbitro1")
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

        call(post(path(match) + "/events").content(body("START", null, null, 0)), "arbitro2")
                .andExpect(status().isForbidden());
        call(post(path(match) + "/events").content(body("START", null, null, 0)), "club1")
                .andExpect(status().isForbidden());
        call(get(path(match)), "club1").andExpect(status().isOk());
        call(get(path(match)), "ayudante1").andExpect(status().isForbidden());
        call(get(path(match)), outsider(), PASSWORD).andExpect(status().isNotFound());
    }

    @Test
    void aPointTakenBackAndTheStoppedClockAdjustedAreUndoneLikeAnyAction() throws Exception {
        var match = match(young, 0, 1);
        event(match, "START");
        event(match, "POINT", "RED");
        event(match, "POINT", "RED");
        event(match, "POINT_REMOVED", "RED").andExpect(jsonPath("$.red.points").value(1));
        event(match, "POINT_REMOVED", "BLUE").andExpect(status().isConflict());
        event(match, "POINT_REMOVED").andExpect(status().isBadRequest());
        clock.advance(Duration.ofSeconds(30));

        adjust(match, 10_000).andExpect(status().isConflict());
        event(match, "STOP");
        event(match, "CLOCK_ADJUST").andExpect(status().isBadRequest());
        adjust(match, 10_000)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.remainingMs").value(160_000))
                .andExpect(jsonPath("$.timeline[5].type").value("CLOCK_ADJUST"))
                .andExpect(jsonPath("$.timeline[5].deltaMs").value(10_000))
                .andExpect(jsonPath("$.timeline[5].clockMs").value(30_000));

        event(match, "UNDO")
                .andExpect(jsonPath("$.remainingMs").value(150_000))
                .andExpect(jsonPath("$.timeline[5].undone").value(true));
        event(match, "UNDO").andExpect(jsonPath("$.red.points").value(2));

        var timeline = call(get("/api/v1/events/" + eventId + "/export/timeline.csv"), "club1")
                .andReturn()
                .getResponse()
                .getContentAsString(java.nio.charset.StandardCharsets.UTF_8);
        assertThat(timeline).contains(";Ajuste del reloj;;;añade 10 s;arbitro1;;Sí");
        assertThat(timeline).contains(";Quitar punto;Rojo;");
    }

    @Test
    void aDisqualificationScoresTheLimitForTheRivalUntilUndone() throws Exception {
        var match = match(young, 0, 1);
        event(match, "START");
        event(match, "POINT", "BLUE");
        event(match, "POINT", "RED");
        event(match, "DISQUALIFICATION", "BLUE", "Golpe")
                .andExpect(jsonPath("$.endReason").value("DISQUALIFICATION"))
                .andExpect(jsonPath("$.red.points").value(15))
                .andExpect(jsonPath("$.blue.points").value(0))
                .andExpect(jsonPath("$.blue.disqualified").value(true));
        assertThat(jdbc.sql("select red_score from fight_match where id = ?")
                        .param(match)
                        .query(Integer.class)
                        .single())
                .isEqualTo(15);

        event(match, "UNDO")
                .andExpect(jsonPath("$.endReason").doesNotExist())
                .andExpect(jsonPath("$.red.points").value(1))
                .andExpect(jsonPath("$.blue.points").value(1));
    }

    @Test
    void theClubSetsLengthAndLimitButNotWhileAMatchIsInProgress() throws Exception {
        call(get(settings()), "club1")
                .andExpect(jsonPath("$.matchSeconds").value(180))
                .andExpect(jsonPath("$.pointsLimit").value(15));
        call(put(settings()).content(settingsJson(20, null)), "club1").andExpect(status().isBadRequest());
        call(put(settings()).content(settingsJson(1201, null)), "club1").andExpect(status().isBadRequest());
        call(put(settings()).content(settingsJson(150, 12)), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.matchSeconds").value(150))
                .andExpect(jsonPath("$.pointsLimit").value(12));
        var match = match(young, 0, 1);
        call(get(path(match)), "arbitro1")
                .andExpect(jsonPath("$.lengthSeconds").value(150))
                .andExpect(jsonPath("$.pointsLimit").value(12));

        event(match, "START");
        call(put(settings()).content(settingsJson(120, null)), "club1").andExpect(status().isConflict());
        call(put(settings()).content(settingsJson(null, 15)), "club1").andExpect(status().isConflict());
        call(put(settings()).content(settingsJson(150, 12)), "club1").andExpect(status().isOk());

        event(match, "DISQUALIFICATION", "RED", "Golpe");
        event(match, "FINISH");
        call(put(settings()).content(settingsJson(180, null)), "club1").andExpect(status().isOk());
        call(put(settings()).content(settingsJson(null, 15)), "club1").andExpect(status().isConflict());
    }

    private String settings() {
        return "/api/v1/events/" + eventId + "/settings";
    }

    private String settingsJson(Integer matchSeconds, Integer pointsLimit) {
        var referees = java.util.stream.IntStream.rangeClosed(1, 5)
                .mapToObj(i -> "\"" + accountId("arbitro" + i) + "\"")
                .collect(java.util.stream.Collectors.joining(","));
        return """
                {"name":"Fase 1","date":"2027-03-10","maxGroupsPerMat":1,"matReferees":[%s],
                 "matchSeconds":%s,"pointsLimit":%s}""".formatted(referees, matchSeconds, pointsLimit);
    }

    private ResultActions adjust(UUID match, long deltaMs) throws Exception {
        return call(post(path(match) + "/events").content("""
                        {"type":"CLOCK_ADJUST","deltaMs":%d,"knownEvents":%d}""".formatted(deltaMs, knownEvents(match))), "arbitro1");
    }

    private ResultActions event(UUID match, String type) throws Exception {
        return event(match, type, null, null);
    }

    private ResultActions event(UUID match, String type, String side) throws Exception {
        return event(match, type, side, null);
    }

    private ResultActions event(UUID match, String type, String side, String reason) throws Exception {
        return call(post(path(match) + "/events").content(body(type, side, reason, knownEvents(match))), "arbitro1");
    }

    private static String body(String type, String side, String reason, int knownEvents) {
        return """
                {"type":"%s","side":%s,"reason":%s,"knownEvents":%d}""".formatted(type, quote(side), quote(reason), knownEvents);
    }

    private static String quote(String value) {
        return value == null ? "null" : "\"" + value + "\"";
    }
}
