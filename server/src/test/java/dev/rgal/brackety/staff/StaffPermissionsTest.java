package dev.rgal.brackety.staff;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.event.EventApiTest;
import java.util.UUID;
import org.hamcrest.Matchers;
import org.junit.jupiter.api.Test;

/** F1-7 C: the club chooses what each helper or referee may do; the defaults keep what they did before. */
class StaffPermissionsTest extends EventApiTest {

    @Test
    void helpersAndRefereesStartWithWhatTheirRoleDid() throws Exception {
        call(get("/api/v1/events"), "ayudante1")
                .andExpect(jsonPath("$[0].permissions", Matchers.containsInAnyOrder("GROUPS", "TEAMS", "MEASURES")));
        call(get("/api/v1/events"), "arbitro1")
                .andExpect(jsonPath("$[0].permissions[0]").value("OWN_MAT"));
        call(get("/api/v1/events"), "club1")
                .andExpect(jsonPath("$[0].permissions.length()").value(11));

        call(get(mats()), "ayudante1").andExpect(status().isOk());
        call(get(participants()), "ayudante1").andExpect(status().isForbidden());
        call(post(phase() + "/finish"), "ayudante1").andExpect(status().isForbidden());
        call(get("/api/v1/mats/" + mat(1) + "/board"), "arbitro1").andExpect(status().isOk());
        call(get("/api/v1/mats/" + mat(1) + "/board"), "ayudante1").andExpect(status().isForbidden());
    }

    @Test
    void theClubGivesAndTakesPermissionsButNeverReopensForOthers() throws Exception {
        var helper = accountId("ayudante1");
        call(put(permissions(helper)).content("{\"permissions\":[\"PARTICIPANTS\",\"PHASE\"]}"), "ayudante1")
                .andExpect(status().isForbidden());
        call(put(permissions(helper)).content("{\"permissions\":[\"PARTICIPANTS\",\"PHASE\"]}"), "club1")
                .andExpect(status().isOk());

        call(get(participants()), "ayudante1").andExpect(status().isOk());
        call(get(mats()), "ayudante1").andExpect(status().isForbidden());
        call(post(phase() + "/finish"), "ayudante1")
                .andExpect(jsonPath("$.state").value("FINISHED"));
        call(post(phase() + "/reopen").content("{\"reason\":\"Falta un combate\"}"), "ayudante1")
                .andExpect(status().isForbidden());
        call(get("/api/v1/events/" + eventId + "/settings"), "club1")
                .andExpect(jsonPath("$.staff[?(@.username == 'ayudante1')].permissions[*]")
                        .value(Matchers.containsInAnyOrder("PARTICIPANTS", "PHASE")));

        call(put(permissions(accountId("club1"))).content("{\"permissions\":[]}"), "club1")
                .andExpect(status().isBadRequest());
        call(put(permissions(helper)).content("{\"permissions\":[\"EVERYTHING\"]}"), "club1")
                .andExpect(status().isBadRequest());
    }

    @Test
    void aRefereeWithoutTheirMatPermissionCannotRunIt() throws Exception {
        var referee = accountId("arbitro1");
        call(put(permissions(referee)).content("{\"permissions\":[]}"), "club1").andExpect(status().isOk());

        call(get("/api/v1/mats/" + mat(1) + "/board"), "arbitro1").andExpect(status().isForbidden());
        call(get("/api/v1/events"), "arbitro1")
                .andExpect(jsonPath("$[0].permissions").isEmpty());
    }

    @Test
    void whoeverLeavesTheEventLosesTheChoiceAndANewPhaseKeepsIt() throws Exception {
        call(put(permissions(accountId("ayudante1"))).content("{\"permissions\":[\"REVIEWS\"]}"), "club1")
                .andExpect(status().isOk());
        call(put(permissions(accountId("ayudante2"))).content("{\"permissions\":[\"CONTROL\"]}"), "club1")
                .andExpect(status().isOk());

        call(post("/api/v1/events/" + eventId + "/league/phases").content("""
                        {"name":"Fase 2","date":"2027-04-10","discipline":"TAMBO","attendancePoints":0}"""), "club1")
                .andExpect(status().isCreated());
        assertThat(saved()).isEqualTo(4);

        call(
                        delete("/api/v1/events/" + eventId + "/staff/" + accountId("ayudante1"))
                                .param("role", "GROUPER"),
                        "club1")
                .andExpect(status().isNoContent());
        assertThat(saved()).isEqualTo(3);
    }

    @Test
    void aViewerSeesGroupsAndMatsButChangesNothing() throws Exception {
        call(put(permissions(accountId("ayudante1"))).content("{\"permissions\":[\"VIEW\"]}"), "club1")
                .andExpect(status().isOk());

        call(get("/api/v1/events/" + eventId + "/categories"), "ayudante1").andExpect(status().isOk());
        call(get(mats()), "ayudante1").andExpect(status().isOk());
        call(get("/api/v1/mats/" + mat(2) + "/board"), "ayudante1").andExpect(status().isOk());
        call(
                        post("/api/v1/events/" + eventId + "/groups")
                                .content("{\"categoryId\":\"%s\",\"groups\":[{\"participantIds\":[\"%s\",\"%s\"]}]}"
                                        .formatted(eventId, UUID.randomUUID(), UUID.randomUUID())),
                        "ayudante1")
                .andExpect(status().isForbidden());
        call(post("/api/v1/events/" + eventId + "/control/mats/" + mat(2) + "/disable"), "ayudante1")
                .andExpect(status().isForbidden());
        call(get(participants()), "ayudante1").andExpect(status().isForbidden());
    }

    @Test
    void whoeverManagesParticipantsReadsTheCategoriesButNotTheStaff() throws Exception {
        call(put(permissions(accountId("ayudante1"))).content("{\"permissions\":[\"PARTICIPANTS\"]}"), "club1")
                .andExpect(status().isOk());

        call(get("/api/v1/events/" + eventId + "/settings"), "ayudante1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.categories").isNotEmpty())
                .andExpect(jsonPath("$.staff").isEmpty())
                .andExpect(jsonPath("$.referees").isEmpty());
        call(get("/api/v1/events/" + eventId + "/settings"), "arbitro1").andExpect(status().isForbidden());
    }

    @Test
    void aHelperWhoMayRefereeCanBeOnAMat() throws Exception {
        call(get("/api/v1/events/" + eventId + "/settings"), "club1")
                .andExpect(jsonPath("$.referees[?(@.username == 'ayudante1')]").isEmpty());

        call(put(permissions(accountId("ayudante1"))).content("{\"permissions\":[\"GROUPS\",\"OWN_MAT\"]}"), "club1")
                .andExpect(status().isOk());

        call(get("/api/v1/events/" + eventId + "/settings"), "club1")
                .andExpect(jsonPath("$.referees[?(@.username == 'ayudante1')]").isNotEmpty());
    }

    private int saved() {
        return jdbc.sql("select count(*) from event_staff_permissions")
                .query(Integer.class)
                .single();
    }

    private Object mat(int number) {
        return jdbc.sql("select id from mat where event_id = ? and number = ?")
                .params(eventId, number)
                .query(UUID.class)
                .single();
    }

    private String permissions(UUID member) {
        return "/api/v1/events/" + eventId + "/staff/" + member + "/permissions";
    }

    private String mats() {
        return "/api/v1/events/" + eventId + "/mats";
    }

    private String participants() {
        return "/api/v1/events/" + eventId + "/participants";
    }

    private String phase() {
        return "/api/v1/events/" + eventId + "/phase";
    }
}
