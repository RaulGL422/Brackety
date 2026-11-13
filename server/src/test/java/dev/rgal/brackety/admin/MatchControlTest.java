package dev.rgal.brackety.admin;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/** The control panel (MatchControlService) as the club and as the superadmin, with its limits. */
class MatchControlTest extends AdminApiTestBase {

    @Test
    void aGroupMovesWithItsPendingMatchesButNotWhileOneIsInProgress() throws Exception {
        var first = match(young, 0, 1);
        var group = groupOf(first);
        var target = freeMat();

        referee(first, "START", null, 0);
        club(put(control() + "/groups/" + group + "/mat").content(mat(target)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("MATCH_IN_PROGRESS"));
        clock.advance(Duration.ofMinutes(2));
        referee(first, "FINISH", null, 1);

        club(put(control() + "/groups/" + group + "/mat").content(mat(target))).andExpect(status().isNoContent());

        assertThat(rows("select count(*) from fight_match where group_id = ? and mat_id = ?", group, target))
                .isEqualTo(5);
        // The played one stays where it was played.
        assertThat(rows("select count(*) from fight_match where id = ? and mat_id = ?", first, target))
                .isZero();
        assertThat(rows("select count(*) from fight_group where id = ? and mat_id = ?", group, target))
                .isOne();
    }

    @Test
    void oneMatchMovesToAnotherMatWithAReferee() throws Exception {
        var match = match(young, 2, 3);
        var target = freeMat();

        club(put(control() + "/matches/" + match + "/mat").content(mat(target))).andExpect(status().isNoContent());
        assertThat(rows("select count(*) from fight_match where id = ? and mat_id = ?", match, target))
                .isOne();
        // Its new referee runs it.
        var number = rows("select number from mat where id = ?", target);
        call(get("/api/v1/mats/" + target + "/board"), "arbitro" + number)
                .andExpect(jsonPath("$.matches[?(@.id == '" + match + "')]").isNotEmpty());

        jdbc.sql("update mat set referee_account_id = null where id = ?")
                .param(target)
                .update();
        club(put(control() + "/matches/" + match(young, 0, 1) + "/mat").content(mat(target)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("MAT_WITHOUT_REFEREE"));
    }

    @Test
    void thePendingMatchesTakeTheOrderGivenAndKeepThePlayedOnesPlace() throws Exception {
        var group = groupOf(match(young, 0, 1));
        var order = pendingOrder(group);
        var reversed = new ArrayList<>(order);
        java.util.Collections.reverse(reversed);

        club(put(control() + "/groups/" + group + "/order").content(ids(reversed)))
                .andExpect(status().isNoContent());
        assertThat(pendingOrder(group)).containsExactlyElementsOf(reversed);
        var board = call(get("/api/v1/mats/" + matOf(order.getFirst()) + "/board"), "arbitro1")
                .andReturn()
                .getResponse()
                .getContentAsString();
        assertThat((String) JsonPath.read(board, "$.recommendedMatchId"))
                .isEqualTo(reversed.getFirst().toString());

        // Every pending match, once: a stale list is refused.
        club(put(control() + "/groups/" + group + "/order").content(ids(reversed.subList(0, 5))))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ORDER_CHANGED"));
    }

    @Test
    void aMatchCanBeLetStartWithoutTheLeastRest() throws Exception {
        var first = match(young, 0, 1);
        referee(first, "START", null, 0);
        clock.advance(Duration.ofMinutes(2));
        referee(first, "FINISH", null, 1);
        var next = jdbc.sql("select id from fight_match where status = 'PENDING' and (red_participant_id = ?"
                        + " or blue_participant_id = ?) limit 1")
                .params(young.get(0), young.get(0))
                .query(UUID.class)
                .single();
        call(post("/api/v1/matches/" + next + "/events").content("""
                        {"type":"START","knownEvents":0}"""), "arbitro1")
                .andExpect(status().isConflict());

        club(post(control() + "/matches/" + next + "/waive-rest")).andExpect(status().isNoContent());

        call(get("/api/v1/matches/" + next), "arbitro1")
                .andExpect(jsonPath("$.readyAt").doesNotExist());
        referee(next, "START", null, 0);
        assertThat(rows(
                        "select count(*) from fight_match where id = ? and rest_waived_by = ?",
                        next,
                        accountId("club1")))
                .isOne();
    }

    @Test
    void theSuperadminDoesTheSameAndItIsAudited() throws Exception {
        var match = match(young, 2, 3);
        admin(put("/api/v1/admin/events/" + eventId + "/control/matches/" + match + "/mat")
                        .content(mat(freeMat())))
                .andExpect(status().isNoContent());
        admin(post("/api/v1/admin/events/" + eventId + "/control/matches/" + match + "/waive-rest"))
                .andExpect(status().isNoContent());

        assertThat(rows(
                        "select count(*) from admin_audit where action = 'CONTROL_CHANGE' and target = ?",
                        match.toString()))
                .isEqualTo(2);
        assertThat(rows("select count(*) from fight_match where id = ? and rest_waived_at is not null", match))
                .isOne();

        // Its event view lists the real teams with their people, for moving someone between teams.
        var team = jdbc.sql("select id from event_category where name = '15-16'")
                .query(UUID.class)
                .single();
        var teens = participants(15, "Teen");
        call(
                        post("/api/v1/events/" + eventId + "/categories/" + team + "/teams")
                                .content("{\"participantIds\":[\"%s\",\"%s\"]}".formatted(teens.get(0), teens.get(1))),
                        "ayudante1")
                .andExpect(status().isCreated());
        admin(get("/api/v1/admin/events/" + eventId))
                .andExpect(jsonPath("$.teams[0].category").value("15-16"))
                .andExpect(jsonPath("$.teams[0].groupNumber").doesNotExist())
                .andExpect(jsonPath("$.teams[0].groupStarted").value(false))
                .andExpect(jsonPath("$.teams[0].members[*].participantId")
                        .value(org.hamcrest.Matchers.containsInAnyOrder(
                                teens.get(0).toString(), teens.get(1).toString())));
    }

    @Test
    void aRefereeMovesOnlyTheirOwnMatches() throws Exception {
        var match = match(young, 2, 3);
        var target = freeMat();
        var body = mat(target);

        call(post("/api/v1/matches/" + match + "/move").content(body), "arbitro2")
                .andExpect(status().isForbidden());
        call(post("/api/v1/matches/" + match + "/move").content(body), "arbitro1")
                .andExpect(status().isNoContent());
        assertThat(rows("select count(*) from fight_match where id = ? and mat_id = ?", match, target))
                .isOne();
    }

    @Test
    void onlyTheClub() throws Exception {
        var match = match(young, 2, 3);
        for (var user : List.of("ayudante1", "arbitro1")) {
            call(post(control() + "/matches/" + match + "/waive-rest"), user).andExpect(status().isForbidden());
        }
        call(post(control() + "/matches/" + match + "/waive-rest"), outsider(), PASSWORD)
                .andExpect(status().isNotFound());
    }

    @Test
    void aStartedMatchNeverChanges() throws Exception {
        var match = match(young, 0, 1);
        referee(match, "START", null, 0);
        club(put(control() + "/matches/" + match + "/mat").content(mat(freeMat())))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("MATCH_NOT_PENDING"));
        club(post(control() + "/matches/" + match + "/waive-rest"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("MATCH_NOT_PENDING"));
    }

    private ResultActions club(MockHttpServletRequestBuilder request) throws Exception {
        return call(request, "club1");
    }

    private String control() {
        return "/api/v1/events/" + eventId + "/control";
    }

    private UUID groupOf(UUID match) {
        return jdbc.sql("select group_id from fight_match where id = ?")
                .param(match)
                .query(UUID.class)
                .single();
    }

    private UUID matOf(UUID match) {
        return jdbc.sql("select mat_id from fight_match where id = ?")
                .param(match)
                .query(UUID.class)
                .single();
    }

    // A mat with a referee and no group.
    private UUID freeMat() {
        return jdbc.sql("select id from mat where event_id = ? and referee_account_id is not null and id not in"
                        + " (select mat_id from fight_group where mat_id is not null) order by number limit 1")
                .param(eventId)
                .query(UUID.class)
                .single();
    }

    private List<UUID> pendingOrder(UUID group) {
        return jdbc.sql("select id from fight_match where group_id = ? and status = 'PENDING' order by order_index")
                .param(group)
                .query(UUID.class)
                .list();
    }

    private static String mat(UUID mat) {
        return """
                {"matId":"%s"}""".formatted(mat);
    }

    private static String ids(List<UUID> ids) {
        return """
                {"matchIds":[%s]}""".formatted(ids.stream().map(id -> "\"" + id + "\"").collect(Collectors.joining(",")));
    }
}
