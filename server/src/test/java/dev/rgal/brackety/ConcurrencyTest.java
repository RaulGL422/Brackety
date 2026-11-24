package dev.rgal.brackety;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.event.EventApiTest;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * Server battery, «Concurrencia» (docs/04-testing.md, GR-8): two devices at once on the same match, group, student
 * or session. Each race runs several rounds; whatever order the server takes, there are never two states nor lost
 * data.
 */
class ConcurrencyTest extends EventApiTest {

    @Autowired
    ParticipantRepository participants;

    @Test
    void twoDevicesScoringOneMatchAtOnceCountOnce() throws Exception {
        var match = firstMatchOf(group(1, students(4)));
        var tablet = token("arbitro1");
        var phone = token("arbitro1");
        assertThat(send(tablet, action(match, "START", null, 0)).getStatus()).isEqualTo(200);

        for (int round = 0; round < 10; round++) {
            var known = knownEvents(match);
            var statuses = atOnce(
                    () -> send(tablet, action(match, "POINT", "RED", known)).getStatus(),
                    () -> send(phone, action(match, "POINT", "BLUE", known)).getStatus());
            assertThat(statuses).containsExactlyInAnyOrder(200, 409);
        }

        assertThat(count("select count(*) from match_event where match_id = ? and type = 'POINT'", match))
                .isEqualTo(10);
        assertThat(knownEvents(match)).isEqualTo(11);
        assertThat(reviewReason(match)).isNull();
    }

    @Test
    void twoQueuedActionsAtOnceApplyOneAndSendTheOtherToReview() throws Exception {
        var match = firstMatchOf(group(1, students(4)));
        var tablet = token("arbitro1");
        var phone = token("arbitro1");
        assertThat(send(tablet, action(match, "START", null, 0)).getStatus()).isEqualTo(200);

        var statuses = atOnce(
                () -> send(tablet, queued(match, "POINT", "RED", UUID.randomUUID(), 1))
                        .getStatus(),
                () -> send(phone, queued(match, "POINT", "BLUE", UUID.randomUUID(), 1))
                        .getStatus());

        assertThat(statuses).containsExactlyInAnyOrder(200, 409);
        assertThat(count("select count(*) from match_event where match_id = ? and type = 'POINT'", match))
                .isEqualTo(1);
        assertThat(count("select count(*) from offline_rejected_op where match_id = ?", match))
                .isEqualTo(1);
        assertThat(reviewReason(match)).isEqualTo("KNOWN_EVENTS");
    }

    @Test
    void theSameQueuedActionSentTwiceAtOnceIsAppliedOnce() throws Exception {
        var match = firstMatchOf(group(1, students(4)));
        var tablet = token("arbitro1");
        assertThat(send(tablet, action(match, "START", null, 0)).getStatus()).isEqualTo(200);

        for (int round = 0; round < 5; round++) {
            var opId = UUID.randomUUID();
            var known = knownEvents(match);
            var statuses = atOnce(
                    () -> send(tablet, queued(match, "POINT", "RED", opId, known))
                            .getStatus(),
                    () -> send(tablet, queued(match, "POINT", "RED", opId, known))
                            .getStatus());
            assertThat(statuses).containsExactly(200, 200);
            assertThat(count("select count(*) from match_event where op_id = ?", opId))
                    .isEqualTo(1);
        }
        assertThat(reviewReason(match)).isNull();
    }

    @Test
    void oneStudentInTwoNewGroupsAtOnceEndsInOne() throws Exception {
        var category = category("4-6");
        var first = token("ayudante1");
        var second = token("ayudante2");

        for (int round = 0; round < 5; round++) {
            var kids = students(7);
            var shared = kids.get(3);
            var statuses = atOnce(
                    () -> send(first, createGroup(category, mat(1), kids.subList(0, 4)))
                            .getStatus(),
                    () -> send(second, createGroup(category, mat(2), kids.subList(3, 7)))
                            .getStatus());
            assertThat(statuses).containsExactlyInAnyOrder(201, 409);
            assertThat(count("select count(*) from group_member where participant_id = ? and not ghost", shared))
                    .isEqualTo(1);
        }
    }

    @Test
    void aGroupMovedToTwoMatsAtOnceEndsWholeOnOne() throws Exception {
        var group = group(1, students(4));
        var laptop = token("club1");
        var tablet = token("club1");

        for (int round = 0; round < 5; round++) {
            var statuses = atOnce(
                    () -> send(laptop, moveGroup(group, mat(3))).getStatus(),
                    () -> send(tablet, moveGroup(group, mat(4))).getStatus());
            assertThat(statuses).containsExactly(204, 204);
            assertThat(count("""
                            select count(distinct m.mat_id) from fight_match m join fight_group g on g.id = m.group_id
                            where g.id = ? and m.mat_id <> g.mat_id""", group)).isZero();
        }
    }

    @Test
    void aGroupMovedWhileAnotherDeviceUndoesItIsGoneWhole() throws Exception {
        var club = token("club1");
        var helper = token("ayudante1");

        for (int round = 0; round < 5; round++) {
            var kids = students(4);
            var group = group(1, kids);
            var statuses = atOnce(
                    () -> send(club, moveGroup(group, mat(3))).getStatus(),
                    () -> send(helper, delete("/api/v1/events/" + eventId + "/groups/" + group))
                            .getStatus());

            assertThat(statuses.get(0)).isIn(204, 404);
            assertThat(statuses.get(1)).isEqualTo(204);
            assertThat(count("select count(*) from fight_group where id = ?", group))
                    .isZero();
            assertThat(count("select count(*) from fight_match where group_id = ?", group))
                    .isZero();
            assertThat(count("select count(*) from group_member where participant_id = any(?)", (Object)
                            kids.toArray(UUID[]::new)))
                    .isZero();
        }
    }

    @Test
    void aGroupMovedWhileItsMatchStartsIsEitherMovedOrStarted() throws Exception {
        var club = token("club1");
        var referee = token("arbitro1");

        for (int round = 0; round < 5; round++) {
            var group = group(1, students(4));
            var match = firstMatchOf(group);
            var statuses = atOnce(
                    () -> send(club, moveGroup(group, mat(3))).getStatus(),
                    () -> send(referee, action(match, "START", null, 0)).getStatus());

            var started = count("select count(*) from fight_match where id = ? and status = 'IN_PROGRESS'", match);
            if (started == 1) {
                assertThat(statuses).containsExactly(409, 200);
                assertThat(matNumberOf(match)).isEqualTo(1);
                // Stop it, so mat 1 is free for the next round.
                jdbc.sql("delete from match_event where match_id = ?")
                        .param(match)
                        .update();
                jdbc.sql("update fight_match set status = 'PENDING' where id = ?")
                        .param(match)
                        .update();
            } else {
                assertThat(statuses).containsExactly(204, 403);
                assertThat(matNumberOf(match)).isEqualTo(3);
            }
            assertThat(count("select count(*) from match_event where match_id = ?", match))
                    .isZero();
        }
    }

    @Test
    void twoRenewalsWithOneTokenAtOnceKeepTheSession() throws Exception {
        for (int round = 0; round < 5; round++) {
            var refresh = JsonPath.<String>read(login("arbitro2"), "$.refreshToken");

            var answers = atOnce(() -> renew(refresh), () -> renew(refresh));

            assertThat(answers).extracting(MockHttpServletResponse::getStatus).containsExactly(200, 200);
            var tokens = new ArrayList<String>();
            for (var answer : answers) {
                tokens.add(JsonPath.read(body(answer), "$.refreshToken"));
            }
            assertThat(tokens.get(0)).isEqualTo(tokens.get(1));
            assertThat(renew(tokens.get(0)).getStatus()).isEqualTo(200);
        }
        assertThat(count(
                        "select count(*) from refresh_token where revoked_at is not null and account_id = ?",
                        accountId("arbitro2")))
                .isZero();
    }

    @Test
    void oneQrScannedTwiceAtOnceOpensOneSession() throws Exception {
        var club = token("club1");

        for (int round = 0; round < 5; round++) {
            var created = body(send(
                    club,
                    post("/api/v1/events/" + eventId + "/temporary-access")
                            .content("{\"name\":\"Juan %d\",\"role\":\"REFEREE\",\"mat\":3}".formatted(round))));
            var link = JsonPath.<String>read(created, "$.link");
            var code = link.substring(link.indexOf("code=") + 5);
            var signIn = post("/api/v1/auth/temporary").content("{\"token\":\"%s\"}".formatted(code));

            var statuses = atOnce(
                    () -> perform(signIn).getStatus(), () -> perform(signIn).getStatus());

            assertThat(statuses).containsExactlyInAnyOrder(200, 400);
            assertThat(count("""
                            select count(*) from refresh_token t join temporary_access a on a.account_id = t.account_id
                            where a.event_id = ? and a.name = ? and t.revoked_at is null and t.used_at is null""", eventId, "Juan " + round)).isEqualTo(1);
        }
    }

    // Two (or more) calls released together; their answers in the same order.
    @SafeVarargs
    private static <T> List<T> atOnce(Callable<T>... calls) throws Exception {
        var start = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(calls.length)) {
            var futures = Arrays.stream(calls)
                    .map(call -> pool.submit(() -> {
                        if (!start.await(30, TimeUnit.SECONDS)) {
                            throw new IllegalStateException("Start signal never came");
                        }
                        return call.call();
                    }))
                    .toList();
            start.countDown();
            var answers = new ArrayList<T>();
            for (var future : futures) {
                answers.add(future.get(30, TimeUnit.SECONDS));
            }
            return answers;
        }
    }

    private String token(String username) {
        return auth.login(username, username, "127.0.0.1").accessToken();
    }

    private MockHttpServletResponse send(String token, MockHttpServletRequestBuilder request) throws Exception {
        return perform(request.header(HttpHeaders.AUTHORIZATION, "Bearer " + token));
    }

    private MockHttpServletResponse perform(MockHttpServletRequestBuilder request) throws Exception {
        return mvc.perform(request.contentType(MediaType.APPLICATION_JSON))
                .andReturn()
                .getResponse();
    }

    private static String body(MockHttpServletResponse response) throws Exception {
        return response.getContentAsString();
    }

    private String login(String username) throws Exception {
        return body(perform(post("/api/v1/auth/login")
                .content("{\"email\":\"%s\",\"password\":\"%s\"}".formatted(username, username))));
    }

    private MockHttpServletResponse renew(String refresh) throws Exception {
        return perform(post("/api/v1/auth/refresh").content("{\"refreshToken\":\"%s\"}".formatted(refresh)));
    }

    private static MockHttpServletRequestBuilder action(UUID match, String type, String side, int knownEvents) {
        return post("/api/v1/matches/" + match + "/events")
                .content("{\"type\":\"%s\",\"side\":%s,\"knownEvents\":%d}"
                        .formatted(type, side == null ? "null" : "\"" + side + "\"", knownEvents));
    }

    private MockHttpServletRequestBuilder queued(UUID match, String type, String side, UUID opId, int knownEvents) {
        return post("/api/v1/matches/" + match + "/events")
                .content("{\"type\":\"%s\",\"side\":\"%s\",\"opId\":\"%s\",\"at\":\"%s\",\"knownEvents\":%d}"
                        .formatted(type, side, opId, clock.instant(), knownEvents));
    }

    private MockHttpServletRequestBuilder createGroup(UUID category, UUID mat, List<UUID> members) {
        var ids = members.stream().map(id -> "\"" + id + "\"").collect(Collectors.joining(","));
        return post("/api/v1/events/" + eventId + "/groups")
                .content("{\"categoryId\":\"%s\",\"matId\":\"%s\",\"groups\":[{\"participantIds\":[%s]}]}"
                        .formatted(category, mat, ids));
    }

    private MockHttpServletRequestBuilder moveGroup(UUID group, UUID mat) {
        return put("/api/v1/events/" + eventId + "/control/groups/" + group + "/mat")
                .content("{\"matId\":\"%s\"}".formatted(mat));
    }

    /** A group of the 4-6 category on mat {@code number}, made by a helper. */
    private UUID group(int number, List<UUID> members) throws Exception {
        var created = send(token("ayudante1"), createGroup(category("4-6"), mat(number), members));
        assertThat(created.getStatus()).isEqualTo(201);
        return UUID.fromString(JsonPath.read(body(created), "$.groupIds[0]"));
    }

    /** Six-year-olds in the 4-6 category: free to be grouped. */
    private List<UUID> students(int count) {
        var ids = new ArrayList<UUID>();
        for (int i = 0; i < count; i++) {
            var participant = new Participant(eventId, clock.instant());
            participant.update(
                    "Peque" + UUID.randomUUID().toString().substring(0, 6),
                    "Prueba",
                    LocalDate.of(2021, 3, 1),
                    110,
                    true);
            ids.add(participants.save(participant).getId());
        }
        return ids;
    }

    private UUID firstMatchOf(UUID group) {
        return jdbc.sql("select id from fight_match where group_id = ? order by order_index limit 1")
                .param(group)
                .query(UUID.class)
                .single();
    }

    private UUID mat(int number) {
        return jdbc.sql("select id from mat where event_id = ? and number = ?")
                .params(eventId, number)
                .query(UUID.class)
                .single();
    }

    private int matNumberOf(UUID match) {
        return jdbc.sql("select m.number from fight_match f join mat m on m.id = f.mat_id where f.id = ?")
                .param(match)
                .query(Integer.class)
                .single();
    }

    private UUID category(String name) {
        return jdbc.sql("select id from event_category where event_id = ? and name = ?")
                .params(eventId, name)
                .query(UUID.class)
                .single();
    }

    private String reviewReason(UUID match) {
        return jdbc.sql("select review_reason from fight_match where id = ?")
                .param(match)
                .query(String.class)
                .optional()
                .orElse(null);
    }

    private int count(String sql, Object... params) {
        return jdbc.sql(sql).params(params).query(Integer.class).single();
    }
}
