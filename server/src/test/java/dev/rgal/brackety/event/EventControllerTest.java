package dev.rgal.brackety.event;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.Arrays;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class EventControllerTest extends EventApiTest {

    @Test
    void eachAccountSeesItsRoleAndTheRefereeItsMat() throws Exception {
        call(get("/api/v1/events"), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].roles", contains("CLUB")))
                .andExpect(jsonPath("$[0].maxGroupsPerMat").value(1))
                .andExpect(jsonPath("$[0].matId").doesNotExist());
        call(get("/api/v1/events"), "arbitro3")
                .andExpect(jsonPath("$[0].roles", contains("REFEREE")))
                .andExpect(jsonPath("$[0].matNumber").value(3));
        call(get("/api/v1/events"), "ayudante1").andExpect(jsonPath("$[0].roles", contains("GROUPER")));
    }

    @Test
    void onlyTheClubSeesTheSettingsAndOutsidersGetNotFound() throws Exception {
        call(get(settings()), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mats", hasSize(5)))
                .andExpect(jsonPath("$.referees", hasSize(5)))
                .andExpect(jsonPath("$.categories[0].name").value("4-6"));
        call(get(settings()), "arbitro1").andExpect(status().isForbidden());
        call(get(settings()), outsider(), PASSWORD).andExpect(status().isNotFound());
    }

    @Test
    void clubChangesMatsSwapsRefereesAndEnablesMultigroup() throws Exception {
        var referee1 = accountId("arbitro1");
        var referee2 = accountId("arbitro2");

        call(put(settings()).content(settingsJson(2, referee2, referee1)), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.maxGroupsPerMat").value(2))
                .andExpect(jsonPath("$.mats", hasSize(2)))
                .andExpect(jsonPath("$.mats[0].refereeId").value(referee2.toString()))
                .andExpect(jsonPath("$.mats[1].refereeId").value(referee1.toString()));

        call(put(settings()).content(settingsJson(1, referee1, null, null)), "club1")
                .andExpect(jsonPath("$.mats", hasSize(3)))
                .andExpect(jsonPath("$.mats[2].refereeId").doesNotExist());
        assertThat(count("mat")).isEqualTo(3);
    }

    @Test
    void rejectsANonRefereeARefereeOnTwoMatsAndNonClubs() throws Exception {
        var referee = accountId("arbitro1");

        call(put(settings()).content(settingsJson(1, accountId("ayudante1"))), "club1")
                .andExpect(status().isBadRequest());
        call(put(settings()).content(settingsJson(1, referee, referee)), "club1")
                .andExpect(status().isBadRequest());
        call(put(settings()).content(settingsJson(1, referee)), "ayudante1").andExpect(status().isForbidden());
    }

    private String settings() {
        return "/api/v1/events/" + eventId + "/settings";
    }

    private static String settingsJson(int maxGroupsPerMat, UUID... referees) {
        var ids = Arrays.stream(referees)
                .map(r -> r == null ? "null" : "\"" + r + "\"")
                .toList();
        return """
                {"name":"Fase 1","date":"2027-03-10","maxGroupsPerMat":%d,"matReferees":[%s]}""".formatted(maxGroupsPerMat, String.join(",", ids));
    }
}
