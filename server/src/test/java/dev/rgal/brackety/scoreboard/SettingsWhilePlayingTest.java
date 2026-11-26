package dev.rgal.brackety.scoreboard;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.ResultActions;

/** What the club may change in the settings once groups exist and matches are played. */
class SettingsWhilePlayingTest extends ScoreboardApiTest {

    @Test
    void theDateCannotChangeOnceThereAreGroups() throws Exception {
        save("\"date\":\"2027-03-11\"").andExpect(status().isConflict());
        call(get(settings()), "club1").andExpect(jsonPath("$.date").value("2027-03-10"));

        save("\"date\":\"2027-03-10\"").andExpect(status().isOk());
    }

    @Test
    void theLengthCannotChangeWhileAMatchIsInProgress() throws Exception {
        var seconds = currentInt("$.matchSeconds");
        save("\"matchSeconds\":%d".formatted(seconds + 30)).andExpect(status().isOk());

        start(match(young, 0, 1));

        save("\"matchSeconds\":%d".formatted(seconds)).andExpect(status().isConflict());
        save("\"teamMatchSeconds\":%d".formatted(seconds)).andExpect(status().isConflict());
        call(get(settings()), "club1").andExpect(jsonPath("$.matchSeconds").value(seconds + 30));
        save("\"matchSeconds\":%d".formatted(seconds + 30)).andExpect(status().isOk());
    }

    @Test
    void thePointsLimitAndSuperiorityCannotChangeOnceAMatchHasStarted() throws Exception {
        save("\"pointsLimit\":7").andExpect(status().isOk());

        start(match(young, 0, 1));

        save("\"pointsLimit\":8").andExpect(status().isConflict());
        save("\"teamPointsLimit\":9").andExpect(status().isConflict());
        save("\"superiorityGap\":5").andExpect(status().isConflict());
        call(get(settings()), "club1").andExpect(jsonPath("$.pointsLimit").value(7));
        save("\"pointsLimit\":7,\"attendancePoints\":2").andExpect(status().isOk());
    }

    private void start(UUID match) throws Exception {
        call(post(path(match) + "/events").content("{\"type\":\"START\",\"knownEvents\":0}"), "arbitro1")
                .andExpect(status().isOk());
    }

    // The same name and mats as now, with the given fields changed.
    private ResultActions save(String fields) throws Exception {
        var referees = jdbc
                .sql("select referee_account_id from mat where event_id = ? order by number")
                .param(eventId)
                .query(UUID.class)
                .list()
                .stream()
                .map(r -> r == null ? "null" : "\"" + r + "\"")
                .collect(Collectors.joining(","));
        var date = fields.contains("\"date\"") ? "" : "\"date\":\"2027-03-10\",";
        var body = "{\"name\":\"Fase 1\",%s\"matReferees\":[%s],%s}".formatted(date, referees, fields);
        return call(put(settings()).content(body), "club1");
    }

    private int currentInt(String path) throws Exception {
        var json = call(get(settings()), "club1").andReturn().getResponse().getContentAsString();
        return JsonPath.read(json, path);
    }

    private String settings() {
        return "/api/v1/events/" + eventId + "/settings";
    }
}
