package dev.rgal.brackety.scoreboard;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.nio.charset.StandardCharsets;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.ResultActions;

/** The club imports the CSV of a referee's device that could not send its queue (docs/modulos/offline.md). */
class OfflineImportControllerTest extends ScoreboardApiTest {

    private static final String HEADER =
            "﻿brackety-offline-ops;1\r\nopId;matchId;type;side;reason;at;knownEvents;actor\r\n";

    UUID match;
    UUID referee;

    @BeforeEach
    void pickMatch() {
        match = match(young, 0, 1);
        referee = accountId("arbitro1");
    }

    @Test
    void importsInOrderAsTheRefereeAndASecondImportChangesNothing() throws Exception {
        var csv = HEADER
                + row(UUID.randomUUID(), "START", "", "", "09:00:00", 0)
                + row(UUID.randomUUID(), "POINT", "RED", "", "09:00:10", 1)
                + row(UUID.randomUUID(), "WARNING", "BLUE", "\"Agarre; sin soltar\"", "09:00:20", 2);

        importAs("club1", csv)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.applied").value(3))
                .andExpect(jsonPath("$.duplicates").value(0))
                .andExpect(jsonPath("$.inReview").value(0))
                .andExpect(jsonPath("$.skipped").value(0));
        importAs("club1", csv)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.applied").value(0))
                .andExpect(jsonPath("$.duplicates").value(3));

        call(get(path(match)), "club1")
                .andExpect(jsonPath("$.red.points").value(1))
                .andExpect(jsonPath("$.timeline.length()").value(3))
                .andExpect(jsonPath("$.timeline[0].actor").value("arbitro1"))
                .andExpect(jsonPath("$.timeline[2].reason").value("Agarre; sin soltar"));
    }

    @Test
    void aClockAdjustmentKeepsItsDeltaThroughTheFile() throws Exception {
        var v2 = "﻿brackety-offline-ops;2
opId;matchId;type;side;reason;at;knownEvents;actor;deltaMs
";
        var csv = v2
                + row(UUID.randomUUID(), "START", "", "", "09:00:00", 0).replace("
", ";
")
                + row(UUID.randomUUID(), "STOP", "", "", "09:00:20", 1).replace("
", ";
")
                + row(UUID.randomUUID(), "CLOCK_ADJUST", "", "", "09:00:25", 2).replace("
", ";10000
");

        importAs("club1", csv).andExpect(status().isOk()).andExpect(jsonPath("$.applied").value(3));

        call(get(path(match)), "club1")
                .andExpect(jsonPath("$.timeline[2].type").value("CLOCK_ADJUST"))
                .andExpect(jsonPath("$.timeline[2].deltaMs").value(10000));
    }

    @Test
    void anActionTheDeviceAlreadySentIsADuplicate() throws Exception {
        var sent = UUID.randomUUID();
        call(post(path(match) + "/events").content("""
                                {"type":"START","opId":"%s","at":"2027-03-10T09:00:00Z","knownEvents":0}""".formatted(sent)), "arbitro1")
                .andExpect(status().isOk());

        importAs(
                        "club1",
                        HEADER
                                + row(sent, "START", "", "", "09:00:00", 0)
                                + row(UUID.randomUUID(), "POINT", "BLUE", "", "09:00:05", 1))
                .andExpect(jsonPath("$.duplicates").value(1))
                .andExpect(jsonPath("$.applied").value(1));
        call(get(path(match)), "club1").andExpect(jsonPath("$.blue.points").value(1));
    }

    @Test
    void aClashGoesToTheClubsReview() throws Exception {
        importAs("club1", HEADER + row(UUID.randomUUID(), "START", "", "", "09:00:00", 4))
                .andExpect(jsonPath("$.inReview").value(1));

        call(get(path(match)), "club1").andExpect(jsonPath("$.review.reason").value("KNOWN_EVENTS"));
    }

    @Test
    void aWrongFileChangesNothing() throws Exception {
        var foreign = HEADER
                + row(UUID.randomUUID(), "START", "", "", "09:00:00", 0)
                + "%s;%s;POINT;RED;;2027-03-10T09:00:01Z;1;\r\n".formatted(UUID.randomUUID(), UUID.randomUUID());

        importAs("club1", foreign).andExpect(status().isBadRequest());
        importAs("club1", "opId;matchId\r\n").andExpect(status().isBadRequest());
        importAs("club1", HEADER + "x;y;z\r\n").andExpect(status().isBadRequest());

        call(get(path(match)), "club1")
                .andExpect(jsonPath("$.timeline.length()").value(0));
    }

    @Test
    void onlyTheClubImports() throws Exception {
        var csv = HEADER + row(UUID.randomUUID(), "START", "", "", "09:00:00", 0);

        importAs("arbitro1", csv).andExpect(status().isForbidden());
        importAs("ayudante1", csv).andExpect(status().isForbidden());
        importAs(outsider(), PASSWORD, csv).andExpect(status().isNotFound());
        mvc.perform(post(importPath()).contentType("text/csv").content(csv)).andExpect(status().isUnauthorized());
    }

    private String row(UUID opId, String type, String side, String reason, String time, int knownEvents) {
        return "%s;%s;%s;%s;%s;2027-03-10T%sZ;%d;%s\r\n"
                .formatted(opId, match, type, side, reason, time, knownEvents, referee);
    }

    private String importPath() {
        return "/api/v1/events/" + eventId + "/offline-ops/import";
    }

    private ResultActions importAs(String username, String csv) throws Exception {
        return importAs(username, username, csv);
    }

    private ResultActions importAs(String username, String password, String csv) throws Exception {
        var token = auth.login(username, password, "127.0.0.1").accessToken();
        return mvc.perform(post(importPath())
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .contentType(new MediaType("text", "csv"))
                .content(csv.getBytes(StandardCharsets.UTF_8)));
    }
}
