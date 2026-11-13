package dev.rgal.brackety.grouping;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.event.EventApiTest;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.time.Duration;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.ResultActions;

/**
 * One person in two places of the same category (Raul, 2026-11-13): in a team and as a wildcard in another group's
 * wildcard team, in two wildcard teams, in an individual group and in a wildcard team, or in a team and as an
 * individual wildcard. Whatever the mix, while they fight on one mat their other match waits (board and server), and
 * after it they rest the least rest before the other one starts. The 15-16 of the demo event: teams of 3, 5 mats.
 */
class WildcardOverlapTest extends EventApiTest {

    private static final int INDIVIDUAL_SECONDS = 60;
    private static final int TEAM_SECONDS = 180;
    private static final int REST_SECONDS = 30;

    @Autowired
    ParticipantRepository participants;

    // 0-17 make teams 1-6 (0-2, 3-5…); 18-23 have no team.
    private List<UUID> teens;
    private List<UUID> teams;

    @BeforeEach
    void teamsAndLooseOnes() throws Exception {
        jdbc.sql("update event set match_seconds = ?, team_match_seconds = ?, min_rest_seconds = ?")
                .params(INDIVIDUAL_SECONDS, TEAM_SECONDS, REST_SECONDS)
                .update();
        teens = new ArrayList<>();
        for (int i = 0; i < 24; i++) {
            var participant = new Participant(eventId, clock.instant());
            participant.update("Persona" + i, "Prueba", LocalDate.of(2027, 3, 1).minusYears(15), 160, true);
            teens.add(participants.save(participant).getId());
        }
        teams = new ArrayList<>();
        for (int t = 0; t < 6; t++) {
            var body = call(
                            post(event() + "/categories/" + category() + "/teams")
                                    .content(
                                            "{\"participantIds\":[%s]}".formatted(quoted(3 * t, 3 * t + 1, 3 * t + 2))),
                            "ayudante1")
                    .andExpect(status().isCreated())
                    .andReturn()
                    .getResponse()
                    .getContentAsString();
            teams.add(UUID.fromString(JsonPath.read(body, "$.id")));
        }
    }

    @Test
    void aTeamMemberWhoIsAWildcardInAnotherGroupWaitsAndRests() throws Exception {
        var first = createGroup(teamGroup(0, 1, 2, 18, 19, 20));
        // Person 0 fights for team 1 in the first group and as a wildcard in the second.
        var second = createGroup(teamGroup(3, 4, 5, 0, 21, 22));

        checkWaitsAndRests(matchOf(first, 0), "arbitro2", matchOf(second, 0), "arbitro3", TEAM_SECONDS);
    }

    @Test
    void someoneInTwoWildcardTeamsOfTwoGroupsWaitsAndRests() throws Exception {
        var first = createGroup(teamGroup(0, 1, 2, 18, 19, 20));
        var second = createGroup(teamGroup(3, 4, 5, 18, 21, 22));

        checkWaitsAndRests(matchOf(first, 18), "arbitro2", matchOf(second, 18), "arbitro3", TEAM_SECONDS);
    }

    @Test
    void anIndividualFighterWhoIsAWildcardInATeamMakesTheTeamMatchWait() throws Exception {
        // Without a team, 18-21 fight an individual group (mat 1); 18 also fills a wildcard team.
        var individual = createGroup(individualGroup(new int[] {18, 19, 20, 21}));
        var ofTeams = createGroup(teamGroup(0, 1, 2, 18, 22, 23));

        checkWaitsAndRests(matchOf(individual, 18), "arbitro1", matchOf(ofTeams, 18), "arbitro2", INDIVIDUAL_SECONDS);
    }

    @Test
    void aWildcardTeamInAMatchMakesTheIndividualMatchOfOneOfThemWait() throws Exception {
        var individual = createGroup(individualGroup(new int[] {18, 19, 20, 21}));
        var ofTeams = createGroup(teamGroup(0, 1, 2, 18, 22, 23));

        checkWaitsAndRests(matchOf(ofTeams, 18), "arbitro2", matchOf(individual, 18), "arbitro1", TEAM_SECONDS);
    }

    @Test
    void aTeamMemberWhoIsAnIndividualWildcardWaitsBothWays() throws Exception {
        // Person 0 (team 1) fills an individual group of those without a team.
        var individual = createGroup(individualGroup(new int[] {18, 19, 20}, 0));
        var ofTeams = createGroup(teamGroup(0, 1, 2, 21, 22, 23));

        checkWaitsAndRests(matchOf(ofTeams, 0), "arbitro2", matchOf(individual, 0), "arbitro1", TEAM_SECONDS);
        // And back: their next team match waits for the individual one they are fighting now.
        var nextTeamMatch = pendingMatchOf(ofTeams, 0);
        var nextIndividual = pendingMatchOf(individual, 0);
        finish(matchOf(individual, 0), "arbitro1", INDIVIDUAL_SECONDS);
        clock.advance(Duration.ofSeconds(REST_SECONDS));
        checkWaitsAndRests(nextIndividual, "arbitro1", nextTeamMatch, "arbitro2", INDIVIDUAL_SECONDS);
    }

    @Test
    void theWildcardIsNeverStartedTwiceEvenFromAnotherMatOrWhenTheMatsRace() throws Exception {
        var first = createGroup(teamGroup(0, 1, 2, 18, 19, 20));
        var second = createGroup(teamGroup(3, 4, 5, 18, 21, 22));
        var a = matchOf(first, 18);
        var b = matchOf(second, 18);

        start(a, "arbitro4").andExpect(status().isOk());
        // Whichever mat tries, the second one is refused while the first is on.
        for (var referee : List.of("arbitro2", "arbitro3", "arbitro5")) {
            start(b, referee).andExpect(status().isConflict());
        }
        assertThat(inProgressWith(teens.get(18))).isOne();
    }

    /**
     * Found by the mixed simulated day: with no changeover, a match whose time is over but not yet finished left its
     * mat "free now" in the planned queues, while the dispatch still saw it busy. The planned queue then gave that
     * mat a team match and another mat's recommendation was on no board. Every recommendation must be on its board.
     */
    @Test
    void aMatchOverItsTimeKeepsItsMatBusyInThePlannedQueues() throws Exception {
        jdbc.sql("update event set changeover_seconds = 0").update();
        var first = createGroup(teamGroup(0, 1, 2, 18, 19, 20));
        createGroup(teamGroup(3, 4, 5, 21, 22, 23));
        start(matchOf(first, 0), "arbitro2").andExpect(status().isOk());
        clock.advance(Duration.ofSeconds(TEAM_SECONDS));

        var recommendations = 0;
        for (int mat = 1; mat <= 5; mat++) {
            var board = call(get("/api/v1/mats/" + matId(mat) + "/board"), "arbitro" + mat)
                    .andReturn()
                    .getResponse()
                    .getContentAsString();
            String recommended = JsonPath.read(board, "$.recommendedMatchId");
            if (recommended == null) {
                continue;
            }
            recommendations++;
            List<String> available = JsonPath.read(board, "$.matches[?(@.available == true)].id");
            assertThat(available).as("mat %d: %s", mat, board).contains(recommended);
        }
        assertThat(recommendations)
                .as("the idle mats get the free team matches")
                .isEqualTo(3);
    }

    /**
     * {@code first} starts on {@code firstReferee}'s mat: {@code second} (same person) shows BUSY with where they are
     * and when they will be free, and cannot start; after {@code first}, RESTING and refused; after the rest, it
     * starts.
     */
    private void checkWaitsAndRests(
            UUID first, String firstReferee, UUID second, String secondReferee, int firstSeconds) throws Exception {
        start(first, firstReferee).andExpect(status().isOk());
        var startedAt = clock.instant();
        var firstMat = matNumber(first);

        var shown = boardEntry(second);
        assertThat(shown.get("available")).isEqualTo(false);
        assertThat(shown.get("waitReason")).isEqualTo("BUSY");
        assertThat(cornerValues(shown, "fightingOnMat")).contains(firstMat);
        assertThat(cornerValues(shown, "freeAt"))
                .contains(startedAt.plusSeconds(firstSeconds + REST_SECONDS).toString());
        start(second, secondReferee).andExpect(status().isConflict());

        finish(first, firstReferee, firstSeconds);
        assertThat(boardEntry(second).get("waitReason")).isEqualTo("RESTING");
        start(second, secondReferee)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("FIGHTER_RESTING"));

        clock.advance(Duration.ofSeconds(REST_SECONDS));
        // Free now (a hint that another mat may call it first does not lock it).
        assertThat(boardEntry(second).get("available")).isEqualTo(true);
        start(second, secondReferee).andExpect(status().isOk());
        assertThat(inProgressWith(sharedPerson(first, second))).isOne();
    }

    private void finish(UUID match, String referee, int seconds) throws Exception {
        clock.advance(Duration.ofSeconds(seconds));
        act(match, "FINISH", referee).andExpect(status().isOk());
    }

    private ResultActions start(UUID match, String referee) throws Exception {
        return act(match, "START", referee);
    }

    private ResultActions act(UUID match, String type, String referee) throws Exception {
        return call(
                post("/api/v1/matches/" + match + "/events").content("""
                                {"type":"%s","knownEvents":%d}""".formatted(type, knownEvents(match))), referee);
    }

    /** The match as some mat's board shows it (a pool match is on one mat's planned queue). */
    @SuppressWarnings("unchecked")
    private Map<String, Object> boardEntry(UUID match) throws Exception {
        for (int mat = 1; mat <= 5; mat++) {
            var board = call(get("/api/v1/mats/" + matId(mat) + "/board"), "arbitro" + mat)
                    .andReturn()
                    .getResponse()
                    .getContentAsString();
            List<Map<String, Object>> found = JsonPath.read(board, "$.matches[?(@.id == '" + match + "')]");
            if (!found.isEmpty()) {
                return found.getFirst();
            }
        }
        throw new AssertionError("match " + match + " is on no board");
    }

    @SuppressWarnings("unchecked")
    private static List<Object> cornerValues(Map<String, Object> match, String key) {
        var values = new ArrayList<Object>();
        for (var side : List.of("redCorner", "blueCorner")) {
            var corner = (Map<String, Object>) match.get(side);
            if (corner != null) {
                values.add(corner.get(key));
            }
        }
        return values;
    }

    /** The first match (in the group's order) of {@code person} in that group. */
    private UUID matchOf(UUID group, int person) {
        return matchesOf(group, person, "").getFirst();
    }

    private UUID pendingMatchOf(UUID group, int person) {
        return matchesOf(group, person, " and f.status = 'PENDING'").getFirst();
    }

    private List<UUID> matchesOf(UUID group, int person, String filter) {
        return jdbc.sql("""
                        select f.id from fight_match f where f.group_id = ? and (? in (f.red_participant_id,
                          f.blue_participant_id) or exists (select 1 from team_member tm
                          where tm.team_id in (f.red_team_id, f.blue_team_id) and tm.participant_id = ?))""" + filter + " order by f.order_index")
                .params(group, teens.get(person), teens.get(person))
                .query(UUID.class)
                .list();
    }

    private UUID sharedPerson(UUID a, UUID b) {
        return jdbc.sql("""
                        select p from (select red_participant_id p, id from fight_match
                          union all select blue_participant_id, id from fight_match
                          union all select tm.participant_id, f.id from fight_match f join team_member tm
                            on tm.team_id in (f.red_team_id, f.blue_team_id)) x
                        where p is not null and id = ? and p in (select p from (
                          select red_participant_id p, id from fight_match
                          union all select blue_participant_id, id from fight_match
                          union all select tm.participant_id, f.id from fight_match f join team_member tm
                            on tm.team_id in (f.red_team_id, f.blue_team_id)) y where id = ?) limit 1""").params(a, b).query(UUID.class).single();
    }

    /** Matches in progress with {@code person}, alone or in a team. */
    private int inProgressWith(UUID person) {
        return jdbc.sql("""
                        select count(*) from fight_match f where f.status = 'IN_PROGRESS' and (? in
                          (f.red_participant_id, f.blue_participant_id) or exists (select 1 from team_member tm
                          where tm.team_id in (f.red_team_id, f.blue_team_id) and tm.participant_id = ?))""").params(person, person).query(Integer.class).single();
    }

    private int matNumber(UUID match) {
        return jdbc.sql("select m.number from fight_match f join mat m on m.id = f.mat_id where f.id = ?")
                .param(match)
                .query(Integer.class)
                .single();
    }

    private UUID createGroup(String group) throws Exception {
        var body = call(post(event() + "/groups").content("""
                                {"categoryId":"%s","groups":[%s]}""".formatted(category(), group)), "ayudante1")
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        return UUID.fromString(JsonPath.read(body, "$.groupIds[0]"));
    }

    /** Teams {@code a}, {@code b}, {@code c} (0-5) and a wildcard team of three people. */
    private String teamGroup(int a, int b, int c, int x, int y, int z) {
        var ids = List.of(teams.get(a), teams.get(b), teams.get(c)).stream()
                .map(id -> "\"" + id + "\"")
                .collect(Collectors.joining(","));
        return "{\"teamIds\":[%s],\"ghostTeams\":[[%s]]}".formatted(ids, quoted(x, y, z));
    }

    private String individualGroup(int[] real, int... ghosts) {
        return "{\"participantIds\":[%s],\"ghostIds\":[%s]}".formatted(quoted(real), quoted(ghosts));
    }

    private String quoted(int... positions) {
        return Arrays.stream(positions)
                .mapToObj(i -> "\"" + teens.get(i) + "\"")
                .collect(Collectors.joining(","));
    }

    private String event() {
        return "/api/v1/events/" + eventId;
    }

    private UUID category() {
        return jdbc.sql("select id from event_category where name = '15-16'")
                .query(UUID.class)
                .single();
    }

    private UUID matId(int number) {
        return jdbc.sql("select id from mat where number = ?")
                .param(number)
                .query(UUID.class)
                .single();
    }
}
