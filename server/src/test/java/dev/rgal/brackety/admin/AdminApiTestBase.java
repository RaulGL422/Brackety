package dev.rgal.brackety.admin;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
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
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/** The demo event with two groups of four (4-6 and 9-10) and the superadmin signed in through Access. */
abstract class AdminApiTestBase extends EventApiTest {

    @Autowired
    protected FakeCloudflareAccess cloudflare;

    @Autowired
    ParticipantRepository participants;

    List<UUID> young;
    List<UUID> older;
    String token;

    @BeforeEach
    void createGroupsAndSignIn() throws Exception {
        young = participants(6, "Peque");
        older = participants(9, "Mayor");
        group("4-6", young);
        group("9-10", older);
        token = adminToken();
    }

    ResultActions admin(MockHttpServletRequestBuilder request) throws Exception {
        return mvc.perform(request.contentType(MediaType.APPLICATION_JSON)
                .header(CloudflareAccess.HEADER, cloudflare.assertion())
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token));
    }

    String adminToken() throws Exception {
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

    void referee(UUID match, String type, String side, int known) throws Exception {
        call(
                        post("/api/v1/matches/" + match + "/events")
                                .content("""
                                {"type":"%s","side":%s,"reason":null,"knownEvents":%d}""".formatted(type, side == null ? "null" : "\"" + side + "\"", known)),
                        "arbitro1")
                .andExpect(status().isOk());
    }

    UUID match(List<UUID> group, int red, int blue) {
        return jdbc.sql("select id from fight_match where red_participant_id = ? and blue_participant_id = ?")
                .params(group.get(red), group.get(blue))
                .query(UUID.class)
                .single();
    }

    int rows(String sql, Object... params) {
        return jdbc.sql(sql).params(params).query(Integer.class).single();
    }

    List<UUID> participants(int age, String name) {
        var ids = new ArrayList<UUID>();
        for (int i = 0; i < 4; i++) {
            var participant = new Participant(eventId, clock.instant());
            participant.update(name + i, "Prueba", LocalDate.of(2027, 3, 1).minusYears(age), 110, true);
            ids.add(participants.save(participant).getId());
        }
        return ids;
    }

    void group(String category, List<UUID> members) throws Exception {
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
