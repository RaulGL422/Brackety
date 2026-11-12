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
import java.nio.charset.StandardCharsets;
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

// The demo's "15-16" category is by teams of 3; the event is on 2027-03-10 with 5 mats.
class TeamControllerTest extends EventApiTest {

    @Autowired
    ParticipantRepository participants;

    List<UUID> teens;

    @BeforeEach
    void registerParticipants() {
        teens = new ArrayList<>();
        for (int i = 0; i < 14; i++) {
            teens.add(participant("Alumno" + (char) ('A' + i), 15));
        }
    }

    @Test
    void teamCategoriesSayItAndTeamsAreNumberedThroughTheEvent() throws Exception {
        var first = createTeam(0, 1, 2)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.number").value(1))
                .andExpect(jsonPath("$.members[*].participantId", contains(ids(0, 1, 2))));
        createTeam(3, 4, 5).andExpect(jsonPath("$.number").value(2));

        call(get(event() + "/categories"), "ayudante1")
                .andExpect(jsonPath("$[0].name").value("15-16"))
                .andExpect(jsonPath("$[0].format").value("TEAM"))
                .andExpect(jsonPath("$[0].teamSize").value(3))
                .andExpect(jsonPath("$[0].inTeams").value(6))
                .andExpect(jsonPath("$[0].teams").value(2));
        call(get(event() + "/categories/" + category() + "/participants"), "ayudante2")
                .andExpect(jsonPath("$[0].teamNumber").value(1))
                .andExpect(jsonPath("$[6].teamNumber").doesNotExist());
        call(get(event() + "/categories/" + category() + "/teams"), "ayudante2")
                .andExpect(jsonPath("$[*].number", contains(1, 2)))
                .andExpect(jsonPath("$[0].groupNumber").doesNotExist());

        var firstId = JsonPath.read(first.andReturn().getResponse().getContentAsString(), "$.id");
        call(delete(event() + "/teams/" + firstId), "ayudante1").andExpect(status().isNoContent());
        createTeam(0, 1, 2).andExpect(jsonPath("$.number").value(3));
    }

    @Test
    void rejectsWrongTeamsAndParticipantsAlreadyInATeam() throws Exception {
        createTeam(0, 1, 2).andExpect(status().isCreated());

        createTeam(3, 4).andExpect(status().isBadRequest());
        createTeam(3, 4, 4).andExpect(status().isBadRequest());
        createTeam(2, 3, 4).andExpect(status().isConflict());
        var seven = participant("Peque", 7);
        call(
                        post(event() + "/categories/" + category("7-8") + "/teams")
                                .content(members(seven, seven, seven)),
                        "ayudante1")
                .andExpect(status().isBadRequest());
        call(post(event() + "/categories/" + category() + "/teams").content(members(0, 4, 5)), "arbitro1")
                .andExpect(status().isForbidden());
        call(delete(event() + "/participants/" + teens.get(0)), "club1").andExpect(status().isConflict());
    }

    @Test
    void fourTeamsMakeAGroupWithTeamMatchesOnTheSoonestMat() throws Exception {
        var teams = teams(4);
        createGroups(teamGroup(teams, null))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.matNumber").value(1));

        call(get("/api/v1/mats/" + matId(1) + "/board"), "arbitro1")
                .andExpect(jsonPath("$.groups[0].members[*].teamNumber", contains(1, 2, 3, 4)))
                .andExpect(jsonPath("$.groups[0].members[0].members", hasSize(3)))
                .andExpect(jsonPath("$.matches", hasSize(6)))
                .andExpect(jsonPath("$.matches[*].red.teamNumber", contains(1, 3, 1, 2, 1, 2)))
                .andExpect(jsonPath("$.matches[*].blue.teamNumber", contains(2, 4, 3, 4, 4, 3)))
                .andExpect(jsonPath("$.matches[0].red.participantId").doesNotExist())
                .andExpect(jsonPath("$.recommendedMatchId")
                        .value(teamMatch(teams.get(0), teams.get(1)).toString()));
        call(get(event() + "/categories/" + category() + "/teams"), "ayudante2")
                .andExpect(jsonPath("$[0].groupNumber").value(1))
                .andExpect(jsonPath("$[0].matNumber").value(1));

        createGroups(teamGroup(teams, null)).andExpect(status().isConflict());
        call(delete(event() + "/teams/" + teams.get(0)), "ayudante1").andExpect(status().isConflict());
    }

    @Test
    void aGhostTeamIsAnyThreeOfTheCategoryButNotFromTheGroupsOwnTeams() throws Exception {
        var teams = teams(4);
        var three = teams.subList(0, 3);

        createGroups(teamGroup(three, quoted(9, 10))).andExpect(status().isBadRequest());
        createGroups(teamGroup(three, quoted(0, 9, 10))).andExpect(status().isBadRequest());
        createGroups(teamGroup(three, quoted(9, 10, 11))).andExpect(status().isCreated());

        call(get("/api/v1/mats/" + matId(1) + "/board"), "arbitro1")
                .andExpect(jsonPath("$.groups[0].members[3].ghost").value(true))
                .andExpect(jsonPath("$.groups[0].members[3].teamNumber").value(5));
        // The ghost team is made of team 4's members, which stays free to be grouped; ghosts are not listed.
        call(get(event() + "/categories/" + category() + "/teams"), "ayudante1")
                .andExpect(jsonPath("$[*].number", contains(1, 2, 3, 4)))
                .andExpect(jsonPath("$[3].groupNumber").doesNotExist());
    }

    @Test
    void anIndividualGroupInATeamCategoryOnlyTakesThoseWithoutATeam() throws Exception {
        createTeam(0, 1, 2).andExpect(status().isCreated());

        createGroups(individualGroup(2, 3, 4, 5)).andExpect(status().isConflict());
        createGroups(individualGroup(3, 4, 5, 6))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.groupNumbers", contains(1)));
        createTeam(3, 7, 8).andExpect(status().isConflict());
    }

    @Test
    void aTeamIsBusyWhenAnyMemberFightsAndOnlyItsMatchesWait() throws Exception {
        var teams = teams(3);
        createGroups(individualGroup(12, 13, 9, 10)).andExpect(status().isCreated());
        createGroups(teamGroup(teams, quoted(12, 9, 11))).andExpect(status().isCreated());
        // Participant 12 is fighting on mat 1, so the ghost team (12, 9, 11) on mat 2 must wait.
        jdbc.sql("update fight_match set status = 'IN_PROGRESS', started_at = ? where id = ?")
                .params(
                        Timestamp.from(clock.instant()),
                        jdbc.sql("select id from fight_match where red_participant_id = ? and blue_participant_id = ?")
                                .params(teens.get(12), teens.get(13))
                                .query(UUID.class)
                                .single())
                .update();

        call(get("/api/v1/mats/" + matId(2) + "/board"), "arbitro2")
                .andExpect(jsonPath("$.matches[?(@.order == 1)].available", contains(false)))
                .andExpect(jsonPath("$.matches[?(@.order == 0)].available", contains(true)));
    }

    @Test
    void everyTeamMemberGetsAttendanceAndTheTeamsPointsButTheGhostTeamNothing() throws Exception {
        var teams = teams(3);
        createGroups(teamGroup(teams, quoted(9, 10, 11))).andExpect(status().isCreated());
        var ghostTeam =
                jdbc.sql("select id from team where ghost").query(UUID.class).single();

        var match = teamMatch(teams.get(0), teams.get(1));
        call(get("/api/v1/matches/" + match), "arbitro1")
                .andExpect(jsonPath("$.red.teamNumber").value(1))
                .andExpect(jsonPath("$.red.members", hasSize(3)))
                .andExpect(jsonPath("$.red.oneHandRule").value(false));
        referee(match, "START", null);
        points(match, "RED", 15);
        referee(match, "FINISH", null);
        var ghostMatch = teamMatch(teams.get(2), ghostTeam);
        referee(ghostMatch, "START", null);
        points(ghostMatch, "RED", 4);
        points(ghostMatch, "BLUE", 15);
        referee(ghostMatch, "FINISH", null);

        call(get(event() + "/standings"), "club1")
                .andExpect(jsonPath("$[?(@.participantId == '%s')].total".formatted(teens.get(0)))
                        .value(25))
                .andExpect(jsonPath("$[?(@.participantId == '%s')].teamNumber".formatted(teens.get(0)))
                        .value(1))
                .andExpect(jsonPath("$[?(@.participantId == '%s')].total".formatted(teens.get(2)))
                        .value(25))
                .andExpect(jsonPath("$[?(@.participantId == '%s')].total".formatted(teens.get(4)))
                        .value(10))
                .andExpect(jsonPath("$[?(@.participantId == '%s')].total".formatted(teens.get(7)))
                        .value(14))
                .andExpect(jsonPath("$[?(@.participantId == '%s')].matches".formatted(teens.get(7)))
                        .value(1))
                .andExpect(jsonPath("$[?(@.participantId == '%s')].total".formatted(teens.get(9)))
                        .value(0));
        var csv = call(get(event() + "/export/matches.csv"), "club1")
                .andReturn()
                .getResponse()
                .getContentAsString(StandardCharsets.UTF_8);
        // Each team with its members; the club column after each one is empty (no clubs here).
        assertThat(csv).contains(";Equipo 1 (AlumnoA Prueba, AlumnoB Prueba, AlumnoC Prueba);;Equipo 2 (");
    }

    @Test
    void aTeamCanBeMadeOfGhostsOnly() throws Exception {
        teams(1);
        // 0, 1 and 2 are team 1: they fill a whole team in, which can be grouped like any other.
        createTeam(new int[] {0, 1, 2}, 0, 1, 2)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.number").value(2))
                .andExpect(jsonPath("$.members[0].ghost").value(true))
                .andExpect(jsonPath("$.members[2].ghost").value(true));
        call(get(event() + "/categories/" + category() + "/teams"), "ayudante1")
                .andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    void aGhostMemberFillsATeamInWithoutScoringForIt() throws Exception {
        var full = teams(3);
        // 9 and 10 are only two: 0, already in team 1, fills the third place as a ghost.
        var body = createTeam(new int[] {9, 10, 0}, 0)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.members[0].ghost").value(false))
                .andExpect(jsonPath("$.members[2].ghost").value(true))
                .andReturn()
                .getResponse()
                .getContentAsString();
        var filled = UUID.fromString(JsonPath.read(body, "$.id"));
        createTeam(new int[] {11, 12, 13}, 1).andExpect(status().isBadRequest());
        // A real member must still be free: 1 is in team 1.
        createTeam(new int[] {11, 12, 1}, 11).andExpect(status().isConflict());

        // Team 1 and the filled team share 0: they may go in one group (the app warns first).
        createGroups(teamGroup(List.of(full.get(0), full.get(1), full.get(2), filled), null))
                .andExpect(status().isCreated());
        var match = teamMatch(full.get(1), filled);
        call(get("/api/v1/matches/" + match), "arbitro1")
                .andExpect(jsonPath("$.blue.members[2]").value("AlumnoA Prueba (fantasma)"));
        referee(match, "START", null);
        points(match, "BLUE", 15);
        referee(match, "FINISH", null);

        call(get(event() + "/standings"), "club1")
                .andExpect(jsonPath("$[?(@.participantId == '%s')].total".formatted(teens.get(9)))
                        .value(25))
                .andExpect(jsonPath("$[?(@.participantId == '%s')].teamNumber".formatted(teens.get(9)))
                        .value(4))
                // The ghost member: attendance and team number from team 1 only, nothing from the filled team.
                .andExpect(jsonPath("$[?(@.participantId == '%s')].total".formatted(teens.get(0)))
                        .value(10))
                .andExpect(jsonPath("$[?(@.participantId == '%s')].matches".formatted(teens.get(0)))
                        .value(0))
                .andExpect(jsonPath("$[?(@.participantId == '%s')].teamNumber".formatted(teens.get(0)))
                        .value(1));
        call(get(event() + "/categories/" + category() + "/teams"), "ayudante2")
                .andExpect(jsonPath("$[3].members[2].ghost").value(true));
    }

    @Test
    void theClubSetsCategoriesUntilTheyAreInUse() throws Exception {
        createTeam(0, 1, 2).andExpect(status().isCreated());
        var current = call(get(event() + "/settings"), "club1")
                .andExpect(jsonPath("$.categories[5].format").value("TEAM"))
                .andExpect(jsonPath("$.categories[5].groupSize").value(4))
                .andReturn()
                .getResponse()
                .getContentAsString();
        List<String> ids = JsonPath.read(current, "$.categories[*].id");

        // The team category in use keeps its team size, but can change its name.
        updateCategories(categories(ids, "15-16", 2, 4)).andExpect(status().isConflict());
        updateCategories(categories(ids, "Cadete", 3, 4))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[5].name").value("Cadete"));
        updateCategories(categories(ids, "Cadete", 3, 5)).andExpect(status().isBadRequest());
        updateCategories(categories(ids.subList(0, 5), "Cadete", 3, 4)).andExpect(status().isConflict());
        updateCategories("""
                [{"name":"A","minAge":4,"maxAge":10,"format":"INDIVIDUAL","groupSize":4},
                 {"name":"B","minAge":10,"maxAge":20,"format":"INDIVIDUAL","groupSize":4}]""").andExpect(status().isBadRequest());
        call(put(event() + "/categories").content("{\"categories\":" + categories(ids, "X", 3, 4) + "}"), "ayudante1")
                .andExpect(status().isForbidden());
    }

    private UUID participant(String firstName, int age) {
        var participant = new Participant(eventId, clock.instant());
        participant.update(firstName, "Prueba", LocalDate.of(2027, 3, 1).minusYears(age), 160, true);
        return participants.save(participant).getId();
    }

    /** Teams of participants 0-2, 3-5, 6-8… */
    private List<UUID> teams(int count) throws Exception {
        var result = new ArrayList<UUID>();
        for (int i = 0; i < count; i++) {
            var body = createTeam(3 * i, 3 * i + 1, 3 * i + 2)
                    .andExpect(status().isCreated())
                    .andReturn()
                    .getResponse()
                    .getContentAsString();
            result.add(UUID.fromString(JsonPath.read(body, "$.id")));
        }
        return result;
    }

    private ResultActions createTeam(int... positions) throws Exception {
        return call(post(event() + "/categories/" + category() + "/teams").content(members(positions)), "ayudante1");
    }

    /** A team of {@code members} where {@code ghosts} fill it in without scoring. */
    private ResultActions createTeam(int[] members, int... ghosts) throws Exception {
        return call(
                post(event() + "/categories/" + category() + "/teams")
                        .content("""
                        {"participantIds":[%s],"ghostIds":[%s]}""".formatted(quoted(members), quoted(ghosts))),
                "ayudante1");
    }

    private ResultActions createGroups(String group) throws Exception {
        return call(post(event() + "/groups").content("""
                        {"categoryId":"%s","groups":[%s]}""".formatted(category(), group)), "ayudante1");
    }

    private ResultActions updateCategories(String categories) throws Exception {
        return call(put(event() + "/categories").content("{\"categories\":" + categories + "}"), "club1");
    }

    /** The demo's categories with the 6th renamed and resized; ids decide which ones are kept. */
    private String categories(List<String> ids, String sixthName, int teamSize, int groupSize) {
        String[][] bands = {
            {"4-6", "4", "6"},
            {"7-8", "7", "8"},
            {"9-10", "9", "10"},
            {"11-12", "11", "12"},
            {"13-14", "13", "14"},
            {sixthName, "15", "16"},
            {"17-19", "17", "19"},
            {"20-25", "20", "25"},
            {"26+", "26", "120"}
        };
        var result = new ArrayList<String>();
        for (int i = 0; i < ids.size(); i++) {
            var team = i >= 5;
            result.add("""
                    {"id":"%s","name":"%s","minAge":%s,"maxAge":%s,"format":"%s","teamSize":%s,"groupSize":%d}""".formatted(
                            ids.get(i),
                            bands[i][0],
                            bands[i][1],
                            bands[i][2],
                            team ? "TEAM" : "INDIVIDUAL",
                            team ? (i == 5 ? teamSize : 3) : "null",
                            groupSize));
        }
        return "[" + String.join(",", result) + "]";
    }

    private String teamGroup(List<UUID> teams, String ghostTeam) {
        var teamIds = teams.stream().map(id -> "\"" + id + "\"").collect(Collectors.joining(","));
        return ghostTeam == null
                ? "{\"teamIds\":[%s]}".formatted(teamIds)
                : "{\"teamIds\":[%s],\"ghostTeam\":[%s]}".formatted(teamIds, ghostTeam);
    }

    private String individualGroup(int... positions) {
        return "{\"participantIds\":[%s]}".formatted(quoted(positions));
    }

    private String members(int... positions) {
        return "{\"participantIds\":[%s]}".formatted(quoted(positions));
    }

    private static String members(UUID... ids) {
        return "{\"participantIds\":[%s]}"
                .formatted(Arrays.stream(ids).map(id -> "\"" + id + "\"").collect(Collectors.joining(",")));
    }

    private String quoted(int... positions) {
        return Arrays.stream(positions)
                .mapToObj(i -> "\"" + teens.get(i) + "\"")
                .collect(Collectors.joining(","));
    }

    private String[] ids(int... positions) {
        return Arrays.stream(positions).mapToObj(i -> teens.get(i).toString()).toArray(String[]::new);
    }

    private void points(UUID match, String side, int count) throws Exception {
        for (int i = 0; i < count; i++) {
            referee(match, "POINT", side);
        }
    }

    private void referee(UUID match, String type, String side) throws Exception {
        call(
                        post("/api/v1/matches/" + match + "/events").content("""
                                {"type":"%s","side":%s,"reason":null,"knownEvents":%d}""".formatted(
                                        type, side == null ? "null" : "\"" + side + "\"", knownEvents(match))),
                        "arbitro1")
                .andExpect(status().isOk());
    }

    private String event() {
        return "/api/v1/events/" + eventId;
    }

    private UUID category() {
        return category("15-16");
    }

    private UUID category(String name) {
        return jdbc.sql("select id from event_category where name = ?")
                .param(name)
                .query(UUID.class)
                .single();
    }

    private UUID matId(int number) {
        return jdbc.sql("select id from mat where number = ?")
                .param(number)
                .query(UUID.class)
                .single();
    }

    private UUID teamMatch(UUID red, UUID blue) {
        return jdbc.sql("select id from fight_match where red_team_id = ? and blue_team_id = ?")
                .params(red, blue)
                .query(UUID.class)
                .single();
    }
}
