package dev.rgal.brackety.admin;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.auth.admin.CloudflareAccess;
import dev.rgal.brackety.auth.admin.FakeCloudflareAccess;
import dev.rgal.brackety.event.EventApiTest;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

class AdminEventControllerTest extends EventApiTest {

    private static final String REASON = """
            {"reason":"Prueba antes de la fase"}""";

    @Autowired
    FakeCloudflareAccess cloudflare;

    @Autowired
    ParticipantRepository participants;

    List<UUID> young;
    List<UUID> older;
    String token;

    @BeforeEach
    void createGroups() throws Exception {
        young = participants(6, "Peque");
        older = participants(9, "Mayor");
        group("4-6", young);
        group("9-10", older);
        token = adminToken();
    }

    @Test
    void listsEventsWithTheirCountsAPageAtATime() throws Exception {
        admin(get("/api/v1/admin/events?size=1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(1)))
                .andExpect(jsonPath("$.total").value(1))
                .andExpect(jsonPath("$.items[0].id").value(eventId.toString()))
                .andExpect(jsonPath("$.items[0].entries").value(8))
                .andExpect(jsonPath("$.items[0].groups").value(2))
                .andExpect(jsonPath("$.items[0].matches").value(12))
                .andExpect(jsonPath("$.items[0].matchesFinished").value(0));
        admin(get("/api/v1/admin/events?size=101")).andExpect(status().isBadRequest());
        admin(get("/api/v1/admin/events?page=-1")).andExpect(status().isBadRequest());
    }

    @Test
    void theDetailHasMatsGroupsAndTheirMatchesInOrder() throws Exception {
        admin(get("/api/v1/admin/events/" + eventId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mats[0].number").value(1))
                .andExpect(jsonPath("$.mats[0].referee").value("arbitro1"))
                .andExpect(jsonPath("$.groups", hasSize(2)))
                .andExpect(jsonPath("$.groups[0].number").value(1))
                .andExpect(jsonPath("$.groups[0].category").value("4-6"))
                .andExpect(jsonPath("$.groups[0].matches", hasSize(6)))
                .andExpect(jsonPath("$.groups[0].matches[0].order").value(0))
                .andExpect(jsonPath("$.groups[0].matches[0].status").value("PENDING"))
                .andExpect(jsonPath("$.groups[0].matches[0].red.name").value("Peque0 Prueba"));
        admin(get("/api/v1/admin/events/" + UUID.randomUUID())).andExpect(status().isNotFound());
    }

    @Test
    void aResetMatchIsPendingAgainWithNothingRecorded() throws Exception {
        var match = match(young, 0, 1);
        referee(match, "START", null, 0);
        referee(match, "POINT", "RED", 1);

        admin(post("/api/v1/admin/matches/" + match + "/reset").content(REASON)).andExpect(status().isNoContent());

        assertThat(jdbc.sql(
                                "select status || ' ' || red_score || ' ' || (started_at is null) from fight_match where id = ?")
                        .param(match)
                        .query(String.class)
                        .single())
                .isEqualTo("PENDING 0 true");
        assertThat(rows("select count(*) from match_event where match_id = ?", match))
                .isZero();
        assertThat(audit("MATCH_RESET")).containsExactly(match + " Prueba antes de la fase");
        // It can be played again from the start.
        referee(match, "START", null, 0);
    }

    @Test
    void aDissolvedGroupLeavesItsMembersWithoutAGroup() throws Exception {
        var groupId = jdbc.sql("select group_id from fight_match where id = ?")
                .param(match(young, 0, 1))
                .query(UUID.class)
                .single();

        admin(post("/api/v1/admin/groups/" + groupId + "/dissolve").content(REASON))
                .andExpect(status().isNoContent());

        assertThat(rows("select count(*) from fight_group where event_id = ?", eventId))
                .isOne();
        assertThat(rows("select count(*) from group_member where participant_id = ?", young.getFirst()))
                .isZero();
        assertThat(rows("select count(*) from fight_match where group_id = ?", groupId))
                .isZero();
        assertThat(audit("GROUP_DISSOLVED")).containsExactly(groupId + " Prueba antes de la fase");
        // The helper can group them again.
        group("4-6", young);
    }

    @Test
    void aClearedCompetitionKeepsTheEntriesAndStartsGroupsFromOne() throws Exception {
        var team = UUID.randomUUID();
        jdbc.sql("""
                        insert into team (id, event_id, category_id, number, ghost, created_at)
                        values (?, ?, (select id from event_category where name = '4-6'), 1, false, now())""").params(team, eventId).update();
        referee(match(young, 0, 1), "START", null, 0);

        admin(post("/api/v1/admin/events/" + eventId + "/clear-competition").content(REASON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.groups").value(2))
                .andExpect(jsonPath("$.teams").value(1));

        assertThat(rows("select count(*) from fight_group where event_id = ?", eventId))
                .isZero();
        assertThat(rows("select count(*) from fight_match where event_id = ?", eventId))
                .isZero();
        assertThat(rows("select count(*) from team where event_id = ?", eventId))
                .isZero();
        assertThat(rows("select count(*) from participant where event_id = ?", eventId))
                .isEqualTo(8);
        assertThat(rows("select count(*) from mat where event_id = ?", eventId)).isPositive();
        assertThat(audit("COMPETITION_CLEARED")).containsExactly(eventId + " Prueba antes de la fase");
        group("4-6", young);
        assertThat(jdbc.sql("select number from fight_group where event_id = ?")
                        .param(eventId)
                        .query(Integer.class)
                        .single())
                .isOne();
    }

    @Test
    void everyOperationNeedsAReasonAndChangesNothingWithout() throws Exception {
        var match = match(young, 0, 1);
        var blank = """
                {"reason":"  "}""";

        admin(post("/api/v1/admin/matches/" + match + "/reset").content(blank)).andExpect(status().isBadRequest());
        admin(post("/api/v1/admin/events/" + eventId + "/clear-competition").content("{}"))
                .andExpect(status().isBadRequest());

        assertThat(rows("select count(*) from fight_group where event_id = ?", eventId))
                .isEqualTo(2);
        assertThat(rows("select count(*) from admin_audit where reason is not null"))
                .isZero();
    }

    @Test
    void onlyTheSuperadminGetsIn() throws Exception {
        var path = "/api/v1/admin/events/" + eventId + "/clear-competition";
        // A club's own token, even through Access, is not the superadmin's.
        call(post(path).header(CloudflareAccess.HEADER, cloudflare.assertion()).content(REASON), "club1")
                .andExpect(status().isUnauthorized());
        mvc.perform(post(path)
                        .contentType(MediaType.APPLICATION_JSON)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .content(REASON))
                .andExpect(status().isForbidden());
        admin(post("/api/v1/admin/matches/" + UUID.randomUUID() + "/reset").content(REASON))
                .andExpect(status().isNotFound());
        assertThat(rows("select count(*) from fight_group where event_id = ?", eventId))
                .isEqualTo(2);
    }

    private ResultActions admin(MockHttpServletRequestBuilder request) throws Exception {
        return mvc.perform(request.contentType(MediaType.APPLICATION_JSON)
                .header(CloudflareAccess.HEADER, cloudflare.assertion())
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token));
    }

    private String adminToken() throws Exception {
        var body = mvc.perform(post("/api/v1/admin/auth/login")
                        .header(CloudflareAccess.HEADER, cloudflare.assertion())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","password":"%s"}""".formatted(SUPERADMIN_EMAIL, PASSWORD)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }

    private void referee(UUID match, String type, String side, int known) throws Exception {
        call(
                        post("/api/v1/matches/" + match + "/events")
                                .content("""
                                {"type":"%s","side":%s,"reason":null,"knownEvents":%d}""".formatted(type, side == null ? "null" : "\"" + side + "\"", known)),
                        "arbitro1")
                .andExpect(status().isOk());
    }

    private UUID match(List<UUID> group, int red, int blue) {
        return jdbc.sql("select id from fight_match where red_participant_id = ? and blue_participant_id = ?")
                .params(group.get(red), group.get(blue))
                .query(UUID.class)
                .single();
    }

    private int rows(String sql, Object... params) {
        return jdbc.sql(sql).params(params).query(Integer.class).single();
    }

    private List<String> audit(String action) {
        return jdbc.sql("select target || ' ' || reason from admin_audit where action = ?")
                .param(action)
                .query(String.class)
                .list();
    }

    private List<UUID> participants(int age, String name) {
        var ids = new ArrayList<UUID>();
        for (int i = 0; i < 4; i++) {
            var participant = new Participant(eventId, clock.instant());
            participant.update(name + i, "Prueba", LocalDate.of(2027, 3, 1).minusYears(age), 110, true);
            ids.add(participants.save(participant).getId());
        }
        return ids;
    }

    private void group(String category, List<UUID> members) throws Exception {
        var categoryId = jdbc.sql("select id from event_category where name = ?")
                .param(category)
                .query(UUID.class)
                .single();
        var ids = members.stream().map(id -> "\"" + id + "\"").collect(Collectors.joining(","));
        call(post("/api/v1/events/" + eventId + "/groups").content("""
                                {"categoryId":"%s","groups":[{"participantIds":[%s]}]}""".formatted(categoryId, ids)), "ayudante1")
                .andExpect(status().isCreated());
    }
}
