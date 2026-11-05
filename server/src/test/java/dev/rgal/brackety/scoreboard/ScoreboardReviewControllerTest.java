package dev.rgal.brackety.scoreboard;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.ResultActions;

class ScoreboardReviewControllerTest extends ScoreboardApiTest {

    UUID match;

    @BeforeEach
    void pickMatch() {
        match = match(young, 0, 1);
    }

    @Test
    void theViewHasTheServerTimeAndNoReview() throws Exception {
        offline("START", 0)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.serverTime").value(clock.instant().toString()))
                .andExpect(jsonPath("$.review").doesNotExist());
    }

    @Test
    void aClashAnswersWithItsCodeAndTheMatchShowsItsReview() throws Exception {
        offline("START", 0);

        offline("STOP", 0)
                .andExpect(status().isConflict())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.code").value("MATCH_CONFLICT"));
        offline("STOP", 1).andExpect(jsonPath("$.code").value("MATCH_IN_REVIEW"));
        call(post(path(match) + "/events").content("""
                                {"type":"STOP"}"""), "arbitro1")
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("MATCH_IN_REVIEW"));

        call(get(path(match)), "club1")
                .andExpect(jsonPath("$.review.reason").value("KNOWN_EVENTS"))
                .andExpect(jsonPath("$.review.ops", hasSize(2)))
                .andExpect(jsonPath("$.review.ops[0].type").value("STOP"))
                .andExpect(jsonPath("$.review.ops[0].actor").value("arbitro1"))
                .andExpect(jsonPath("$.review.ops[0].receivedAt")
                        .value(clock.instant().toString()));
    }

    @Test
    void aMatchInReviewIsMarkedOnTheBoardAndIsNeverRecommended() throws Exception {
        offline("STOP", 3);

        call(get("/api/v1/mats/" + matOf(match) + "/board"), "club1")
                .andExpect(jsonPath("$.matches[?(@.id == '%s')].inReview".formatted(match))
                        .value(true))
                .andExpect(jsonPath("$.matches[?(@.id == '%s')].available".formatted(match))
                        .value(false))
                .andExpect(jsonPath("$.recommendedMatchId")
                        .value(match(young, 2, 3).toString()));
        call(get("/api/v1/events/" + eventId + "/mats"), "club1")
                .andExpect(jsonPath("$[0].matchesInReview").value(1));
    }

    @Test
    void onlyTheClubReviews() throws Exception {
        offline("START", 0);
        offline("STOP", 0);
        var discard = """
                {"action":"DISCARD"}""";

        call(post(path(match) + "/review").content(discard), "arbitro1").andExpect(status().isForbidden());
        call(post(path(match) + "/review").content(discard), "ayudante1").andExpect(status().isForbidden());
        call(post(path(match) + "/review").content(discard), outsider(), PASSWORD)
                .andExpect(status().isNotFound());
        mvc.perform(post(path(match) + "/review").content(discard).contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnauthorized());

        call(post(path(match) + "/review").content(discard), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.applied").value(0))
                .andExpect(jsonPath("$.skipped").value(0))
                .andExpect(jsonPath("$.match.review").doesNotExist());
        call(post(path(match) + "/review").content(discard), "club1")
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("MATCH_NOT_IN_REVIEW"));
    }

    private ResultActions offline(String type, int knownEvents) throws Exception {
        return call(post(path(match) + "/events").content(offlineBody(type, knownEvents)), "arbitro1");
    }

    private static String offlineBody(String type, int knownEvents) {
        return """
                {"type":"%s","opId":"%s","at":"2027-03-10T09:00:00Z","knownEvents":%d}""".formatted(type, UUID.randomUUID(), knownEvents);
    }
}
