package dev.rgal.brackety.ranking;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.common.GoldenFiles;
import dev.rgal.brackety.event.EventApiTest;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.zip.ZipInputStream;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import tools.jackson.databind.SerializationFeature;
import tools.jackson.databind.json.JsonMapper;

/**
 * The golden check (docs/producto/plan-limpieza.md, L0): a scripted day (two individual groups, one with a wildcard,
 * and a group of teams with a wildcard team; points, the limit, warnings, a disqualification, a correction, an undo,
 * a cancelled start and a point after the time) must export exactly the files saved in src/test/resources/golden.
 * Fictitious people only. Every choice is fixed, so the same day comes out on every run.
 */
class EventExportsGoldenTest extends EventApiTest {

    private static final String CLUB = "club1";
    private static final String HELPER = "ayudante1";
    private static final List<String> FIRST_NAMES = List.of(
            "Lucía", "Hugo", "Martina", "Mateo", "Sofía", "Leo", "Julia", "Daniel", "Paula", "Pablo", "Valeria",
            "Álvaro", "Emma", "Manuel", "Carla", "Adrián", "Noa", "Mario", "Alba", "Diego");

    @Autowired
    ParticipantRepository participants;

    private int named;

    @Test
    void aScriptedDayExportsExactlyTheGoldenFiles() throws Exception {
        // The phase starts at the test clock, not at the database's now().
        jdbc.sql("update event set started_at = ? where id = ?")
                .params(java.sql.Timestamp.from(clock.instant()), eventId)
                .update();
        var kids = people(8, 7);
        var teens = people(12, 15);

        var groupA = group("7-8", """
                {"participantIds":[%s],"ghostIds":[]}""".formatted(quoted(kids.subList(0, 4))), mat(1));
        var groupB = group("7-8", """
                {"participantIds":[%s],"ghostIds":[%s]}""".formatted(quoted(kids.subList(4, 7)), quoted(kids.subList(0, 1))), mat(2));
        var teams = new ArrayList<String>();
        for (int i = 0; i < 3; i++) {
            teams.add(team(teens.subList(i * 3, i * 3 + 3)));
        }
        var teamGroup = group(
                "15-16",
                """
                {"teamIds":[%s],"ghostTeams":[[%s]]}""".formatted(
                                teams.stream().map(t -> "\"" + t + "\"").collect(Collectors.joining(",")),
                                quoted(teens.subList(9, 12))),
                "null");

        var script = 0;
        for (var match : matches(groupA)) {
            play(1, match, script++, true);
        }
        for (var match : matches(groupB)) {
            play(2, match, script++, true);
        }
        for (var match : matches(teamGroup)) {
            play(1 + script % 2, match, script++, false);
        }
        assertThat(jdbc.sql("select count(*) from fight_match where status <> 'FINISHED'")
                        .query(Integer.class)
                        .single())
                .as("matches not finished")
                .isZero();

        GoldenFiles.check("event-day", exports());
    }

    // Each match its own story; with no points limit (teams) the limit story becomes a long match on time.
    private void play(int mat, UUID match, int script, boolean withLimit) throws Exception {
        act(mat, match, "START", null);
        switch (script % 6) {
            case 0 -> {
                points(mat, match, "RED", 3);
                points(mat, match, "BLUE", 1);
                endOnTime(mat, match, withLimit);
            }
            case 1 -> {
                points(mat, match, "BLUE", withLimit ? 15 : 17);
                if (!withLimit) {
                    endOnTime(mat, match, false);
                }
            }
            case 2 -> {
                act(mat, match, "WARNING", "RED");
                act(mat, match, "WARNING", "RED");
                points(mat, match, "BLUE", 1);
                endOnTime(mat, match, withLimit);
            }
            case 3 -> {
                points(mat, match, "RED", 2);
                act(mat, match, "DISQUALIFICATION", "BLUE");
            }
            case 4 -> {
                points(mat, match, "RED", 2);
                act(mat, match, "POINT_REMOVED", "RED");
                points(mat, match, "BLUE", 1);
                act(mat, match, "UNDO", null);
                points(mat, match, "BLUE", 1);
                endOnTime(mat, match, withLimit);
            }
            default -> {
                points(mat, match, "RED", 1);
                act(mat, match, "CANCEL", null);
                act(mat, match, "START", null);
                points(mat, match, "BLUE", 2);
                endOnTime(mat, match, withLimit);
                // The last action's point after the clock reached 0:00 (F1-3).
                points(mat, match, "RED", 1);
            }
        }
        act(mat, match, "FINISH", null);
        // Enough rest for everyone before the next match.
        clock.advance(Duration.ofMinutes(5));
    }

    private void points(int mat, UUID match, String side, int count) throws Exception {
        for (int i = 0; i < count; i++) {
            act(mat, match, "POINT", side);
        }
    }

    private void endOnTime(int mat, UUID match, boolean individual) throws Exception {
        clock.advance(individual ? Duration.ofMinutes(1) : Duration.ofMinutes(3));
    }

    private void act(int mat, UUID match, String type, String side) throws Exception {
        var reason = switch (type) {
            case "WARNING", "DISQUALIFICATION" -> "\"Exceso de potencia\"";
            case "CANCEL" -> "\"Empezado por error\"";
            default -> "null";
        };
        var body = """
                {"type":"%s","side":%s,"reason":%s,"knownEvents":%d}""".formatted(type, side == null ? "null" : "\"" + side + "\"", reason, knownEvents(match));
        send("arbitro" + mat, post("/api/v1/matches/" + match + "/events").content(body), 200);
        clock.advance(Duration.ofSeconds(4));
    }

    private UUID group(String category, String group, String mat) throws Exception {
        var body = """
                {"categoryId":"%s","groups":[%s],"matId":%s}""".formatted(categoryId(category), group, mat);
        var answer = send(HELPER, post("/api/v1/events/" + eventId + "/groups").content(body), 201);
        return UUID.fromString(JsonPath.read(answer, "$.groupIds[0]"));
    }

    private String team(List<UUID> members) throws Exception {
        var category = categoryId("15-16");
        var answer = send(
                HELPER,
                post("/api/v1/events/" + eventId + "/categories/" + category + "/teams")
                        .content("""
                        {"participantIds":[%s]}""".formatted(quoted(members))),
                201);
        return JsonPath.read(answer, "$.id");
    }

    private List<UUID> matches(UUID group) {
        return jdbc.sql("select id from fight_match where group_id = ? order by order_index")
                .param(group)
                .query(UUID.class)
                .list();
    }

    private List<UUID> people(int count, int age) {
        var ids = new ArrayList<UUID>();
        for (int i = 0; i < count; i++) {
            var participant = new Participant(eventId, clock.instant());
            participant.update(
                    FIRST_NAMES.get(named++ % FIRST_NAMES.size()),
                    "Prueba " + age + "-" + i,
                    LocalDate.of(2027, 3, 1).minusYears(age),
                    110 + age * 3 + i,
                    true);
            ids.add(participants.save(participant).getId());
        }
        return ids;
    }

    // What the club downloads, as text: JSON indented so a change reads well in a diff, and every text file of the
    // zips (the PDF is binary and has its own tests).
    private Map<String, String> exports() throws Exception {
        var files = new LinkedHashMap<String, String>();
        files.put("standings.json", indented(download("/standings")));
        files.put("league-standings.json", indented(download("/league/standings")));
        for (var csv :
                List.of("standings.csv", "league-standings.csv", "matches.csv", "timeline.csv", "participants.csv")) {
            files.put(csv, new String(download("/export/" + csv), StandardCharsets.UTF_8));
        }
        unzip("by-category/", download("/export/league-standings-by-category.zip"), files);
        unzip("full/", download("/export/full"), files);
        return files;
    }

    private byte[] download(String path) throws Exception {
        var response = mvc.perform(get("/api/v1/events/" + eventId + path)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token(CLUB)))
                .andReturn()
                .getResponse();
        assertThat(response.getStatus()).as("GET %s", path).isEqualTo(200);
        return response.getContentAsByteArray();
    }

    private String send(String username, MockHttpServletRequestBuilder request, int status) throws Exception {
        var response = mvc.perform(request.header(HttpHeaders.AUTHORIZATION, "Bearer " + token(username))
                        .contentType(MediaType.APPLICATION_JSON))
                .andReturn()
                .getResponse();
        assertThat(response.getStatus())
                .as("%s: %s", request, response.getContentAsString())
                .isEqualTo(status);
        return response.getContentAsString();
    }

    // A fresh token each time: the clock moves on through the day and would expire a kept one.
    private String token(String username) {
        return auth.login(username, username, "127.0.0.1").accessToken();
    }

    private String mat(int number) {
        var id = jdbc.sql("select id from mat where event_id = ? and number = ?")
                .params(eventId, number)
                .query(UUID.class)
                .single();
        return "\"" + id + "\"";
    }

    private UUID categoryId(String name) {
        return jdbc.sql("select id from event_category where event_id = ? and name = ?")
                .params(eventId, name)
                .query(UUID.class)
                .single();
    }

    private static String quoted(List<UUID> ids) {
        return ids.stream().map(id -> "\"" + id + "\"").collect(Collectors.joining(","));
    }

    private static String indented(byte[] json) {
        var mapper =
                JsonMapper.builder().enable(SerializationFeature.INDENT_OUTPUT).build();
        // The indenter uses the system line separator: the same file on Windows and on the CI.
        return mapper.writeValueAsString(mapper.readTree(json)).replace("\r\n", "\n") + "\n";
    }

    private static void unzip(String prefix, byte[] zip, Map<String, String> files) throws IOException {
        try (var in = new ZipInputStream(new ByteArrayInputStream(zip), StandardCharsets.UTF_8)) {
            for (var entry = in.getNextEntry(); entry != null; entry = in.getNextEntry()) {
                if (!entry.getName().endsWith(".pdf")) {
                    files.put(prefix + entry.getName(), new String(in.readAllBytes(), StandardCharsets.UTF_8));
                }
            }
        }
    }
}
