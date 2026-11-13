package dev.rgal.brackety.grouping;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.event.EventApiTest;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.ResultActions;

// The demo event is on 2027-03-10 (AuthTestConfig.START) with 5 mats, one referee each.
class GroupControllerTest extends EventApiTest {

    @Autowired
    ParticipantRepository participants;

    List<UUID> sevens;
    UUID nineYearOld;

    @BeforeEach
    void registerParticipants() {
        sevens = new ArrayList<>();
        for (int i = 0; i < 10; i++) {
            sevens.add(participant("Alumno" + i, 7));
        }
        nineYearOld = participant("Mayor", 9);
    }

    @Test
    void categoriesWithParticipantsComeYoungestFirstWithTheirGroupedCount() throws Exception {
        createGroups(group(0, 1, 2, 3)).andExpect(status().isCreated());

        call(get(event() + "/categories"), "ayudante1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].name", contains("7-8", "9-10")))
                .andExpect(jsonPath("$[0].participants").value(10))
                .andExpect(jsonPath("$[0].grouped").value(4));
    }

    @Test
    void groupsGoToTheMatThatWillBeFreeFirstWithTheRoundRobinMatches() throws Exception {
        createGroups(group(0, 1, 2, 3))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.matNumber").value(1))
                .andExpect(jsonPath("$.groupNumbers", contains(1)));
        createGroups(group(4, 5, 6, 7)).andExpect(jsonPath("$.matNumber").value(2));

        call(get("/api/v1/mats/" + matId(1) + "/board"), "arbitro1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.matches", hasSize(6)))
                .andExpect(jsonPath("$.matches[*].red.participantId", contains(ids(0, 2, 0, 1, 0, 1))))
                .andExpect(jsonPath("$.matches[*].blue.participantId", contains(ids(1, 3, 2, 3, 3, 2))))
                .andExpect(jsonPath("$.recommendedMatchId").value(matchId(0, 1)));
        call(get(event() + "/categories/" + categoryId("7-8") + "/participants"), "ayudante2")
                .andExpect(jsonPath("$[0].firstName").value("Alumno0"))
                .andExpect(jsonPath("$[0].groupNumber").value(1))
                .andExpect(jsonPath("$[0].matNumber").value(1))
                .andExpect(jsonPath("$[8].groupNumber").doesNotExist());
    }

    @Test
    void aHelperCanPickTheMatIfItHasAReferee() throws Exception {
        call(post(event() + "/groups").content(jsonOnMat(matId(3), group(0, 1, 2, 3))), "ayudante1")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.matNumber").value(3));
        call(get("/api/v1/mats/" + matId(3) + "/board"), "arbitro3").andExpect(jsonPath("$.matches", hasSize(6)));

        jdbc.sql("update mat set referee_account_id = null where number = 4").update();
        call(post(event() + "/groups").content(jsonOnMat(matId(4), group(4, 5, 6, 7))), "ayudante1")
                .andExpect(status().isConflict());
        call(post(event() + "/groups").content(jsonOnMat(UUID.randomUUID(), group(4, 5, 6, 7))), "ayudante1")
                .andExpect(status().isBadRequest());
        assertThat(count("fight_group")).isOne();
    }

    @Test
    void multigroupSendsEveryGroupToOneMatOnlyWhenTheEventAllowsIt() throws Exception {
        createGroups(group(0, 1, 2, 3), group(4, 5, 6, 7)).andExpect(status().isBadRequest());
        jdbc.sql("update event set max_groups_per_mat = 2").update();

        createGroups(group(0, 1, 2, 3), group(4, 5, 6, 7))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.matNumber").value(1))
                .andExpect(jsonPath("$.groupNumbers", contains(1, 2)));
        assertThat(count("fight_match")).isEqualTo(12);
    }

    @Test
    void aGhostCanBeFromAnotherGroupButNotFromTheSameOneOrAnotherCategory() throws Exception {
        createGroups(group(0, 1, 2, 3)).andExpect(status().isCreated());

        createGroups(ghostGroup(sevens.get(0), 4, 5, 6))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.matNumber").value(2));
        call(get("/api/v1/mats/" + matId(2) + "/board"), "arbitro2")
                .andExpect(jsonPath("$.groups[0].members[3].ghost").value(true))
                .andExpect(jsonPath("$.groups[0].members[3].participantId")
                        .value(sevens.get(0).toString()));

        createGroups(ghostGroup(sevens.get(7), 7, 8, 9)).andExpect(status().isBadRequest());
        createGroups(ghostGroup(nineYearOld, 7, 8, 9)).andExpect(status().isBadRequest());
    }

    @Test
    void aGroupTakesUpToThreeGhostsButNeedsARealParticipant() throws Exception {
        createGroups(group(0, 1, 2, 3)).andExpect(status().isCreated());

        createGroups(ghostsGroup(ids(0, 1, 2), 4))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.matNumber").value(2));
        call(get("/api/v1/mats/" + matId(2) + "/board"), "arbitro2")
                .andExpect(jsonPath("$.groups[0].members[0].ghost").value(false))
                .andExpect(jsonPath("$.groups[0].members[1].ghost").value(true))
                .andExpect(jsonPath("$.groups[0].members[3].ghost").value(true));
        assertThat(count("fight_match")).isEqualTo(12);

        createGroups(ghostsGroup(ids(0, 1, 2, 3))).andExpect(status().isBadRequest());
        createGroups(ghostsGroup(ids(0, 1, 2), 5, 6)).andExpect(status().isBadRequest());
        createGroups(ghostsGroup(ids(0, 0), 5, 6)).andExpect(status().isBadRequest());
    }

    @Test
    void rejectsWrongSizesParticipantsAlreadyInAGroupAndReferees() throws Exception {
        createGroups(group(0, 1, 2, 3)).andExpect(status().isCreated());

        createGroups(group(4, 5, 6)).andExpect(status().isBadRequest());
        createGroups(group(3, 4, 5, 6)).andExpect(status().isConflict());
        call(post(event() + "/groups").content(json(group(4, 5, 6, 7))), "arbitro1")
                .andExpect(status().isForbidden());
        assertThat(count("fight_group")).isOne();
    }

    @Test
    void aBusyGhostIsNotRecommendedAndOnlyTheMatsRefereeAndTheClubSeeTheBoard() throws Exception {
        createGroups(group(0, 1, 2, 3)).andExpect(status().isCreated());
        createGroups(ghostGroup(sevens.get(0), 4, 5, 6)).andExpect(status().isCreated());
        // Fighter 0 is fighting on mat 1 right now, so their match as a ghost on mat 2 must wait.
        jdbc.sql("update fight_match set status = 'IN_PROGRESS', started_at = ? where id = ?")
                .params(Timestamp.from(clock.instant()), UUID.fromString(matchId(0, 1)))
                .update();

        call(get("/api/v1/mats/" + matId(2) + "/board"), "arbitro2")
                .andExpect(jsonPath("$.matches[?(@.order == 1)].available", contains(false)))
                .andExpect(jsonPath("$.recommendedMatchId").value(matchId(4, 5)));
        call(get("/api/v1/mats/" + matId(2) + "/board"), "club1").andExpect(status().isOk());
        call(get("/api/v1/mats/" + matId(2) + "/board"), "arbitro1").andExpect(status().isForbidden());
        call(get("/api/v1/mats/" + matId(2) + "/board"), "ayudante1").andExpect(status().isForbidden());
    }

    @Test
    void anIndividualWildcardIsBusyAndRestsLikeATeam() throws Exception {
        createGroups(group(0, 1, 2, 3)).andExpect(status().isCreated());
        createGroups(ghostGroup(sevens.get(0), 4, 5, 6)).andExpect(status().isCreated());
        var asGhost = jdbc.sql("select id from fight_match where mat_id = ? and ? in (red_participant_id,"
                        + " blue_participant_id) order by order_index limit 1")
                .params(matId(2), sevens.get(0))
                .query(UUID.class)
                .single();
        refereeAction(matchId(0, 1), "START", 0, "arbitro1").andExpect(status().isOk());

        // Mat 2 sees where the wildcard is and when they will be free: 1:00 of match + 30 s of rest.
        var board = call(get("/api/v1/mats/" + matId(2) + "/board"), "arbitro2")
                .andReturn()
                .getResponse()
                .getContentAsString();
        var match = "$.matches[?(@.id == '" + asGhost + "')]";
        assertThat(JsonPath.<List<Boolean>>read(board, match + ".available")).containsExactly(false);
        assertThat(JsonPath.<List<String>>read(board, match + ".waitReason")).containsExactly("BUSY");
        List<Integer> fighting = JsonPath.read(board, match + "..fightingOnMat");
        assertThat(fighting).contains(1);
        List<String> freeAt = JsonPath.read(board, match + "..freeAt");
        assertThat(freeAt).contains(clock.instant().plusSeconds(90).toString());
        refereeAction(asGhost.toString(), "START", 0, "arbitro2").andExpect(status().isConflict());

        // Done on mat 1: still resting, then free.
        clock.advance(java.time.Duration.ofSeconds(60));
        refereeAction(matchId(0, 1), "FINISH", 1, "arbitro1").andExpect(status().isOk());
        call(get("/api/v1/mats/" + matId(2) + "/board"), "arbitro2")
                .andExpect(jsonPath(match + ".waitReason", contains("RESTING")));
        refereeAction(asGhost.toString(), "START", 0, "arbitro2")
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("FIGHTER_RESTING"));
        clock.advance(java.time.Duration.ofSeconds(30));
        refereeAction(asGhost.toString(), "START", 0, "arbitro2").andExpect(status().isOk());
    }

    private ResultActions refereeAction(String match, String type, int known, String referee) throws Exception {
        return call(post("/api/v1/matches/" + match + "/events").content("""
                                {"type":"%s","knownEvents":%d}""".formatted(type, known)), referee);
    }

    @Test
    void matOverviewEstimatesTheEndFromTheMatchesLeft() throws Exception {
        createGroups(group(0, 1, 2, 3)).andExpect(status().isCreated());

        call(get(event() + "/mats"), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(5)))
                .andExpect(jsonPath("$[0].referee").value("arbitro1"))
                .andExpect(jsonPath("$[0].pendingMatches").value(6))
                .andExpect(jsonPath("$[0].remainingSeconds").value(60 + 5 * 90))
                .andExpect(jsonPath("$[1].remainingSeconds").value(0));
    }

    @Test
    void groupsLockTheDateTheirMatsAndTheirParticipants() throws Exception {
        createGroups(group(0, 1, 2, 3)).andExpect(status().isCreated());
        createGroups(group(4, 5, 6, 7)).andExpect(status().isCreated());
        var referees = Arrays.stream(new int[] {1, 2, 3, 4, 5})
                .mapToObj(i -> "\"" + accountId("arbitro" + i) + "\"")
                .toList();

        call(put(event() + "/settings").content(settings("2027-03-11", referees)), "club1")
                .andExpect(status().isConflict());
        call(put(event() + "/settings").content(settings("2027-03-10", referees.subList(1, 2))), "club1")
                .andExpect(status().isConflict());
        call(delete(event() + "/participants/" + sevens.get(0)), "club1").andExpect(status().isConflict());
        call(delete(event() + "/participants/" + sevens.get(9)), "club1").andExpect(status().isNoContent());
    }

    @Test
    void theHelperUndoesAGroupUntilOneOfItsMatchesStarts() throws Exception {
        var created = createGroups(group(0, 1, 2, 3))
                .andExpect(jsonPath("$.groupIds", hasSize(1)))
                .andReturn()
                .getResponse()
                .getContentAsString();
        String groupId = JsonPath.read(created, "$.groupIds[0]");
        call(get(event() + "/categories/" + categoryId("7-8") + "/participants"), "ayudante2")
                .andExpect(jsonPath("$[?(@.firstName == 'Alumno0')].groupId").value(groupId))
                .andExpect(
                        jsonPath("$[?(@.firstName == 'Alumno0')].groupStarted").value(false));

        call(delete(event() + "/groups/" + groupId), "arbitro1").andExpect(status().isForbidden());
        call(delete(event() + "/groups/" + UUID.randomUUID()), "ayudante2").andExpect(status().isNotFound());
        call(delete(event() + "/groups/" + groupId), "ayudante2").andExpect(status().isNoContent());
        assertThat(count("fight_group")).isZero();
        assertThat(count("fight_match")).isZero();
        call(get(event() + "/categories"), "ayudante1")
                .andExpect(jsonPath("$[0].grouped").value(0));

        var again = createGroups(group(0, 1, 2, 3)).andReturn().getResponse().getContentAsString();
        String secondId = JsonPath.read(again, "$.groupIds[0]");
        call(post("/api/v1/matches/" + matchId(0, 1) + "/events").content("""
                                {"type":"START","knownEvents":0}"""), "arbitro1")
                .andExpect(status().isOk());
        call(get(event() + "/categories/" + categoryId("7-8") + "/participants"), "ayudante1")
                .andExpect(
                        jsonPath("$[?(@.firstName == 'Alumno3')].groupStarted").value(true));
        call(delete(event() + "/groups/" + secondId), "club1")
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("GROUP_STARTED"));
        assertThat(count("fight_group")).isOne();
    }

    private UUID participant(String firstName, int age) {
        var participant = new Participant(eventId, clock.instant());
        participant.update(firstName, "Prueba", LocalDate.of(2027, 3, 1).minusYears(age), 120, true);
        return participants.save(participant).getId();
    }

    private ResultActions createGroups(String... groups) throws Exception {
        return call(post(event() + "/groups").content(json(groups)), "ayudante1");
    }

    private String json(String... groups) {
        return """
                {"categoryId":"%s","groups":[%s]}""".formatted(categoryId("7-8"), String.join(",", groups));
    }

    private String jsonOnMat(UUID matId, String... groups) {
        return """
                {"categoryId":"%s","groups":[%s],"matId":"%s"}""".formatted(categoryId("7-8"), String.join(",", groups), matId);
    }

    private String group(int... positions) {
        return """
                {"participantIds":[%s]}""".formatted(quoted(positions));
    }

    private String ghostGroup(UUID ghost, int... positions) {
        return """
                {"participantIds":[%s],"ghostIds":["%s"]}""".formatted(quoted(positions), ghost);
    }

    private String ghostsGroup(String[] ghosts, int... positions) {
        return """
                {"participantIds":[%s],"ghostIds":["%s"]}""".formatted(quoted(positions), String.join("\",\"", ghosts));
    }

    private String quoted(int... positions) {
        return Arrays.stream(positions)
                .mapToObj(i -> "\"" + sevens.get(i) + "\"")
                .collect(Collectors.joining(","));
    }

    private String[] ids(int... positions) {
        return Arrays.stream(positions).mapToObj(i -> sevens.get(i).toString()).toArray(String[]::new);
    }

    private static String settings(String date, List<String> referees) {
        return """
                {"name":"Fase 1","date":"%s","maxGroupsPerMat":1,"matReferees":[%s]}""".formatted(date, String.join(",", referees));
    }

    private String event() {
        return "/api/v1/events/" + eventId;
    }

    private UUID matId(int number) {
        return jdbc.sql("select id from mat where number = ?")
                .param(number)
                .query(UUID.class)
                .single();
    }

    private UUID categoryId(String name) {
        return jdbc.sql("select id from event_category where name = ?")
                .param(name)
                .query(UUID.class)
                .single();
    }

    private String matchId(int red, int blue) {
        return jdbc.sql("select id from fight_match where red_participant_id = ? and blue_participant_id = ?")
                .params(sevens.get(red), sevens.get(blue))
                .query(UUID.class)
                .single()
                .toString();
    }
}
