package dev.rgal.brackety.grouping;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.event.EventApiTest;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.time.Duration;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * Whole groups played through the API as the referees would: each mat starts the recommended match, the
 * clock runs out, the match is finished. Ghosts and teams share fighters with other mats; groups arrive
 * while others fight. The recommended match must always start (never a fighter in two matches).
 */
class MatBoardSimulationTest extends EventApiTest {

    @Autowired
    ParticipantRepository participants;

    private final Map<String, String> tokens = new HashMap<>();

    @Test
    void twoMatsWithAGhostFromTheOtherMatAndAGroupCreatedMidwayPlayEveryMatchOnce() throws Exception {
        var first = participants(4, 7);
        var second = participants(3, 7);
        var third = participants(4, 7);
        createGroup("7-8", individual(first, null), 1);
        createGroup("7-8", individual(second, first.get(0)), 2);

        var played = new ArrayList<String>();
        for (int round = 0; round < 40 && played.size() < 18; round++) {
            if (round == 2) {
                createGroup("7-8", individual(third, null), 1);
            }
            played.addAll(playRound(List.of(1, 2)));
        }

        assertThat(played).hasSize(18).doesNotHaveDuplicates();
        assertThat(jdbc.sql("select count(*) from fight_match where status = 'FINISHED'")
                        .query(Integer.class)
                        .single())
                .isEqualTo(18);
    }

    @Test
    void aTeamGroupAndAnIndividualGroupOfTheSameCategoryShareAMatToTheEnd() throws Exception {
        var people = participants(12, 15);
        var teams = new ArrayList<String>();
        for (int t = 0; t < 4; t++) {
            teams.add(createTeam(people.subList(t * 3, t * 3 + 3)));
        }
        createGroup("15-16", """
                {"teamIds":[%s]}""".formatted(quoted(teams)), 1);
        var loners = participants(4, 16);

        var played = new ArrayList<String>();
        for (int round = 0; round < 40 && played.size() < 12; round++) {
            if (round == 1) {
                createGroup("15-16", individual(loners, null), 1);
            }
            played.addAll(playRound(List.of(1)));
        }

        assertThat(played).hasSize(12).doesNotHaveDuplicates();
    }

    @Test
    void aGhostTeamMadeOfAnotherMatsFightersWaitsForThem() throws Exception {
        var people = participants(21, 15);
        var teams = new ArrayList<String>();
        for (int t = 0; t < 7; t++) {
            teams.add(createTeam(people.subList(t * 3, t * 3 + 3)));
        }
        createGroup("15-16", """
                {"teamIds":[%s]}""".formatted(quoted(teams.subList(0, 4))), 1);
        // The ghost team borrows team 1's fighters, who fight on mat 1.
        createGroup(
                "15-16",
                """
                {"teamIds":[%s],"ghostTeam":[%s]}""".formatted(
                        quoted(teams.subList(4, 7)),
                        quoted(people.subList(0, 3).stream().map(UUID::toString).toList())),
                2);

        var played = new ArrayList<String>();
        for (int round = 0; round < 40 && played.size() < 12; round++) {
            played.addAll(playRound(List.of(1, 2)));
        }

        assertThat(played).hasSize(12).doesNotHaveDuplicates();
    }

    /**
     * Every listed mat with nothing in progress starts its recommended match (which must be available);
     * then the clock runs out, every match in progress is finished and the changeover passes.
     */
    private List<String> playRound(List<Integer> matNumbers) throws Exception {
        var started = new ArrayList<String>();
        var busy = new HashSet<String>();
        for (var number : matNumbers) {
            var board = board(number);
            String recommended = JsonPath.read(board, "$.recommendedMatchId");
            List<String> inProgress = JsonPath.read(board, "$.matches[?(@.status == 'IN_PROGRESS')].id");
            if (recommended == null || !inProgress.isEmpty()) {
                continue;
            }
            List<Boolean> available = JsonPath.read(board, "$.matches[?(@.id == '" + recommended + "')].available");
            assertThat(available).containsExactly(true);
            var fighters = fighters(recommended);
            assertThat(fighters).as("a fighter in two matches at once").noneMatch(busy::contains);
            busy.addAll(fighters);
            referee(recommended, "START").andExpect(status().isOk());
            started.add(recommended);
        }
        clock.advance(Duration.ofSeconds(180));
        for (var i = 0; i < started.size(); i++) {
            referee(started.get(i), "FINISH").andExpect(status().isOk());
        }
        clock.advance(Duration.ofSeconds(30));
        // Tokens expire as the clock moves on: log in again next round.
        tokens.clear();
        return started;
    }

    private String board(int matNumber) throws Exception {
        return as("arbitro" + matNumber, get("/api/v1/mats/" + matId(matNumber) + "/board"))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
    }

    /** As the referee of the match's mat. */
    private ResultActions referee(String matchId, String type) throws Exception {
        var mat = jdbc.sql("select m.number from fight_match f join mat m on m.id = f.mat_id where f.id = ?::uuid")
                .param(matchId)
                .query(Integer.class)
                .single();
        return as(
                "arbitro" + mat, post("/api/v1/matches/" + matchId + "/events").content("""
                        {"type":"%s","knownEvents":%d}""".formatted(
                                type, knownEvents(UUID.fromString(matchId)))));
    }

    /** The participants of a match, through teams too. */
    private Set<String> fighters(String matchId) {
        return new HashSet<>(jdbc.sql("""
                        select p from (
                          select red_participant_id p from fight_match where id = ?::uuid
                          union select blue_participant_id from fight_match where id = ?::uuid
                          union select tm.participant_id from fight_match f join team_member tm
                            on tm.team_id in (f.red_team_id, f.blue_team_id) where f.id = ?::uuid) x
                        where p is not null""")
                .params(matchId, matchId, matchId)
                .query(String.class)
                .list());
    }

    private List<UUID> participants(int count, int age) {
        var ids = new ArrayList<UUID>();
        for (int i = 0; i < count; i++) {
            var participant = new Participant(eventId, clock.instant());
            participant.update(
                    "P" + age + "-" + i, "Prueba", LocalDate.of(2027, 3, 1).minusYears(age), 120, true);
            ids.add(participants.save(participant).getId());
        }
        return ids;
    }

    private String createTeam(List<UUID> members) throws Exception {
        var body = as(
                        "ayudante1",
                        post("/api/v1/events/" + eventId + "/categories/" + categoryId("15-16") + "/teams")
                                .content("""
                                        {"participantIds":[%s]}""".formatted(quoted(
                                        members.stream().map(UUID::toString).toList()))))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        return JsonPath.read(body, "$.id");
    }

    private void createGroup(String category, String group, int matNumber) throws Exception {
        as("ayudante1", post("/api/v1/events/" + eventId + "/groups").content("""
                        {"categoryId":"%s","groups":[%s],"matId":"%s"}""".formatted(
                                categoryId(category), group, matId(matNumber))))
                .andExpect(status().isCreated());
    }

    private static String individual(List<UUID> ids, UUID ghost) {
        var list = quoted(ids.stream().map(UUID::toString).toList());
        return ghost == null ? """
                {"participantIds":[%s]}""".formatted(list) : """
                {"participantIds":[%s],"ghostId":"%s"}""".formatted(list, ghost);
    }

    private static String quoted(List<String> ids) {
        return ids.stream().map(id -> "\"" + id + "\"").collect(Collectors.joining(","));
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

    // One login per account: hashing the password on every call would make these runs slow.
    private ResultActions as(String username, MockHttpServletRequestBuilder request) throws Exception {
        var token = tokens.computeIfAbsent(
                username, u -> auth.login(u, u, "127.0.0.1").accessToken());
        return mvc.perform(
                request.header(HttpHeaders.AUTHORIZATION, "Bearer " + token).contentType(MediaType.APPLICATION_JSON));
    }
}
