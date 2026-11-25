package dev.rgal.brackety;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.request;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.auth.admin.CloudflareAccess;
import dev.rgal.brackety.auth.admin.FakeCloudflareAccess;
import dev.rgal.brackety.event.EventApiTest;
import dev.rgal.brackety.event.EventPermission;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.EnumMap;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.UUID;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.request.AbstractMockHttpServletRequestBuilder;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping;

/**
 * Server battery, «Matriz de permisos» (docs/04-testing.md, GR-8): every endpoint × every role, as
 * {@code permission-matrix.txt} says. An endpoint without a row, or a row without an endpoint, fails. A role the row
 * lists must not be refused (401, 403, 404); one it does not list must be. Each call uses the real ids of the demo
 * event with a group, so a missing check shows; a call that changes something gets a fresh event first. With
 * {@code -Dmatrix.update=true} the roles are rewritten from what happens: review the diff in the PR. The same rows
 * serve the «Ataques» that go endpoint by endpoint.
 */
class PermissionMatrixTest extends EventApiTest {

    private static final Path MATRIX = Path.of("src/test/resources/permission-matrix.txt");
    private static final Path GRANTS = Path.of("src/test/resources/permission-grants.txt");
    // What a helper's permissions are about: one event, its matches and its mats.
    private static final Pattern EVENT_SCOPED = Pattern.compile("^/api/v1/(events/\\{eventId}|matches/|mats/)");
    private static final Pattern VARIABLE = Pattern.compile("\\{(\\w+)}");
    // A JSON text that is not an id to fill in, and a JSON whole number.
    private static final Pattern TEXT_VALUE = Pattern.compile(":\"[^\"{]*\"");
    private static final Pattern NUMBER_VALUE = Pattern.compile(":-?\\d+(?=[,}\\]])");
    // A check that always answers 200, with what is wrong in each row: the other event's category is unknown.
    private static final Map<String, String> REFUSED_IN_BODY =
            Map.of("POST /api/v1/events/{eventId}/participants/import/check", "UNKNOWN_CATEGORY");
    private static final byte[] PDF = "%PDF-1.4\n%%EOF\n".getBytes(StandardCharsets.US_ASCII);

    /** In the order they call: the weakest first, so the club's changes come last. */
    enum Role {
        ANONYMOUS,
        OUTSIDER,
        TEMPORARY,
        REFEREE,
        GROUPER,
        SUPERADMIN,
        CLUB;

        String label() {
            return name().toLowerCase();
        }
    }

    record Row(String method, String path, Set<Role> allowed, String body) {

        String key() {
            return method + " " + path;
        }

        static Row parse(String line) {
            var parts = line.split("\\|", 3);
            var endpoint = parts[0].trim().split(" ", 2);
            var roles = EnumSet.noneOf(Role.class);
            for (var r : parts[1].trim().split(" +")) {
                if (!r.isEmpty() && !r.equals("?") && !r.equals("-")) {
                    roles.add(Role.valueOf(r.toUpperCase()));
                }
            }
            return new Row(endpoint[0], endpoint[1], roles, parts.length > 2 ? parts[2].trim() : "");
        }

        String format(Set<Role> roles) {
            var names = roles.isEmpty() ? "-" : roles.stream().map(Role::label).collect(Collectors.joining(" "));
            return body.isEmpty() ? key() + " | " + names : key() + " | " + names + " | " + body;
        }
    }

    /** The demo event as each call sees it: ids for the path and the body, and each role's token. */
    record Fixture(Map<String, String> ids, Map<Role, String> tokens) {}

    @Autowired
    @Qualifier("requestMappingHandlerMapping")
    RequestMappingHandlerMapping mapping;

    @Autowired
    FakeCloudflareAccess cloudflare;

    @Autowired
    ParticipantRepository participants;

    @Test
    void everyEndpointHasItsRowAndEveryRowItsEndpoint() throws IOException {
        var endpoints = new TreeSet<String>();
        mapping.getHandlerMethods().forEach((info, method) -> {
            for (var path : info.getPatternValues()) {
                // The test-only endpoints of AuthTestConfig.
                if (path.startsWith("/api/v1/test/")) {
                    continue;
                }
                for (var verb : info.getMethodsCondition().getMethods()) {
                    endpoints.add(verb + " " + path);
                }
            }
        });

        var listed = rows().stream().map(Row::key).collect(Collectors.toCollection(TreeSet<String>::new));
        assertThat(listed).containsExactlyElementsOf(endpoints);
    }

    @Test
    void everyRoleGetsWhatTheMatrixSays() throws Exception {
        var update = Boolean.getBoolean("matrix.update");
        var rows = rows();
        var observed = new HashMap<Row, Set<Role>>();
        var failures = new ArrayList<String>();
        Fixture fixture = null;
        // The reading calls first, all on one event; -Dmatrix.only=<regex> runs only some rows.
        var only = Pattern.compile(System.getProperty("matrix.only", ".*"));
        var statuses = new ArrayList<String>();
        var ordered = new ArrayList<Row>(
                rows.stream().filter(r -> only.matcher(r.key()).find()).toList());
        ordered.sort(
                (a, b) -> Boolean.compare(!a.method().equals("GET"), !b.method().equals("GET")));
        for (var row : ordered) {
            if (fixture == null) {
                fixture = fixture();
            }
            var allowed = EnumSet.noneOf(Role.class);
            var changed = false;
            for (var role : Role.values()) {
                // Each role on the same event: what the one before changed (a group undone) is put back.
                if (changed) {
                    fixture = fixture();
                }
                var status = call(row, role, fixture);
                changed = !row.method().equals("GET") && status < 300;
                statuses.add("%s as %s: %d".formatted(row.key(), role.label(), status));
                var let = status != 401 && status != 403 && status != 404;
                if (let) {
                    allowed.add(role);
                }
                if (status >= 500) {
                    failures.add("%s as %s: %d".formatted(row.key(), role.label(), status));
                } else if (!update && let != row.allowed().contains(role)) {
                    failures.add("%s as %s: %d, expected %s"
                            .formatted(row.key(), role.label(), status, let ? "refused" : "allowed"));
                }
            }
            observed.put(row, allowed);
            // Something changed: the next row gets a fresh event, so no row depends on another.
            if (changed) {
                fixture = null;
            }
        }
        // Every answer, to review a change of the matrix.
        Files.write(Path.of("target/permission-matrix-statuses.txt"), statuses, StandardCharsets.UTF_8);
        if (update) {
            write(rows, observed);
        }
        assertThat(failures).isEmpty();
    }

    /**
     * «Matriz de permisos», each permission alone (GR-8): the club gives a helper only that permission, and the helper
     * calls every endpoint of the event, its matches and its mats. What each one opens must be what
     * {@code permission-grants.txt} says (one line per endpoint, the permissions that open it); with
     * {@code -Dmatrix.update=true} it is rewritten from what happens: review the diff against ayudantes-permisos.md.
     */
    @Test
    void eachPermissionAloneOpensWhatTheGrantsSay() throws Exception {
        var update = Boolean.getBoolean("matrix.update");
        var rows = new ArrayList<Row>(rows().stream()
                .filter(r -> EVENT_SCOPED.matcher(r.path()).find())
                .toList());
        rows.sort(
                (a, b) -> Boolean.compare(!a.method().equals("GET"), !b.method().equals("GET")));
        var observed = new TreeMap<String, Set<String>>();
        rows.forEach(row -> observed.put(row.key(), new TreeSet<>()));
        var failures = new ArrayList<String>();
        for (var permission : EventPermission.values()) {
            Fixture fixture = null;
            String token = null;
            for (var row : rows) {
                if (fixture == null) {
                    fixture = fixture();
                    token = onlyThis(permission);
                }
                var request = build(row, fixture.ids()).header(HttpHeaders.AUTHORIZATION, "Bearer " + token);
                var status = mvc.perform(request).andReturn().getResponse().getStatus();
                if (status >= 500) {
                    failures.add("%s with %s: %d".formatted(row.key(), permission, status));
                }
                if (status != 401 && status != 403 && status != 404) {
                    observed.get(row.key()).add(permission.name().toLowerCase());
                }
                // It changed the event: the next row gets a fresh one.
                if (!row.method().equals("GET") && status < 300) {
                    fixture = null;
                }
            }
        }
        var lines = new ArrayList<String>();
        observed.forEach((key, opened) -> lines.add(key + " | " + (opened.isEmpty() ? "-" : String.join(" ", opened))));
        if (update) {
            var header = Files.readAllLines(GRANTS, StandardCharsets.UTF_8).stream()
                    .filter(l -> l.startsWith("#"))
                    .toList();
            var all = new ArrayList<>(header);
            all.addAll(lines);
            Files.write(GRANTS, all, StandardCharsets.UTF_8);
        }
        assertThat(failures).isEmpty();
        assertThat(lines)
                .containsExactlyElementsOf(Files.readAllLines(GRANTS, StandardCharsets.UTF_8).stream()
                        .filter(l -> !l.isBlank() && !l.startsWith("#"))
                        .toList());
    }

    /** The club leaves ayudante2 with this permission and no other; returns ayudante2's token. */
    private String onlyThis(EventPermission permission) throws Exception {
        call(
                        put("/api/v1/events/" + eventId + "/staff/" + accountId("ayudante2") + "/permissions")
                                .content("{\"permissions\":[\"" + permission + "\"]}"),
                        "club1")
                .andExpect(status().is2xxSuccessful());
        return login("ayudante2", "ayudante2");
    }

    /**
     * «Ataques», IDOR (GR-8): the club of another event calls every endpoint with its own event in the path and this
     * event's ids everywhere else. Each call is refused and nothing of this event changes.
     */
    @Test
    void anotherClubCannotReachThisEventThroughItsOwn() throws Exception {
        var ids = new HashMap<>(fixture().ids());
        var rival = "rival@example.test";
        auth.register(registration(rival));
        jdbc.sql("update account set email_verified = true where email = ?")
                .param(rival)
                .update();
        var token = "Bearer " + login(rival, PASSWORD);
        var created = mvc.perform(post("/api/v1/events")
                        .header(HttpHeaders.AUTHORIZATION, token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Rival","date":"2027-05-08","discipline":"TAMBO","mats":2}"""))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        var own = UUID.fromString(JsonPath.read(created, "$.eventId"));
        startPhase(own);
        ids.put("eventId", own.toString());
        var before = snapshot(eventId);

        var failures = new ArrayList<String>();
        for (var row : rows()) {
            if (!row.path().contains("{eventId}") || !usesThisEventsIds(row)) {
                continue;
            }
            var answer = mvc.perform(build(row, ids).header(HttpHeaders.AUTHORIZATION, token))
                    .andReturn()
                    .getResponse();
            var status = answer.getStatus();
            var refusedInBody = REFUSED_IN_BODY.containsKey(row.key())
                    && status == 200
                    && answer.getContentAsString().contains(REFUSED_IN_BODY.get(row.key()));
            if ((status < 400 || status >= 500) && !refusedInBody) {
                failures.add(row.key() + ": " + status);
            }
        }

        assertThat(failures).isEmpty();
        assertThat(snapshot(eventId)).isEqualTo(before);
    }

    /**
     * «Ataques», entradas (GR-8): every endpoint, called by a role it lets in, with ids that are not ids, broken or
     * mistyped JSON, 5,000-character texts and numbers out of range. A 4xx or a success, never a server error.
     */
    @Test
    void brokenInputIsNeverAServerError() throws Exception {
        var failures = new ArrayList<String>();
        Fixture fixture = null;
        for (var row : rows()) {
            var role = row.allowed().contains(Role.CLUB)
                    ? Role.CLUB
                    : row.allowed().stream().findFirst().orElse(Role.ANONYMOUS);
            for (var variant : broken(row)) {
                if (fixture == null) {
                    fixture = fixture();
                }
                var status = call(variant, role, fixture);
                if (status >= 500) {
                    failures.add("%s %s: %d".formatted(variant.key(), abbreviate(variant.body()), status));
                }
                if (!row.method().equals("GET") && status < 300) {
                    fixture = null;
                }
            }
        }
        assertThat(failures).isEmpty();
    }

    private static boolean usesThisEventsIds(Row row) {
        return VARIABLE.matcher(row.path() + row.body())
                .results()
                .map(m -> m.group(1))
                .anyMatch(name -> !Set.of("eventId", "type", "matReferees").contains(name));
    }

    private static List<Row> broken(Row row) {
        var variants = new ArrayList<Row>();
        if (VARIABLE.matcher(row.path()).find()) {
            variants.add(new Row(
                    row.method(), VARIABLE.matcher(row.path()).replaceAll("not-an-id"), row.allowed(), row.body()));
        }
        var body = row.body();
        if (body.startsWith("{") || body.startsWith("[")) {
            variants.add(new Row(row.method(), row.path(), row.allowed(), "{\"broken"));
            variants.add(new Row(row.method(), row.path(), row.allowed(), body.startsWith("{") ? "[]" : "{}"));
            for (var changed : List.of(
                    TEXT_VALUE.matcher(body).replaceAll(":\"" + "x".repeat(5000) + "\""),
                    NUMBER_VALUE.matcher(body).replaceAll(":99999999999"),
                    NUMBER_VALUE.matcher(body).replaceAll(":-1"))) {
                if (!changed.equals(body)) {
                    variants.add(new Row(row.method(), row.path(), row.allowed(), changed));
                }
            }
        }
        return variants;
    }

    private static String abbreviate(String body) {
        return body.length() > 80 ? body.substring(0, 80) + "…" : body;
    }

    /** Every row of the event, of its groups' members and of its matches' actions: to see that nothing changed. */
    private String snapshot(UUID event) {
        var tables = jdbc.sql("""
                        select table_name from information_schema.columns
                        where column_name = 'event_id' and table_schema = current_schema()""").query(String.class).list();
        var rows = new ArrayList<String>();
        for (var table : tables) {
            rows.addAll(texts("select t::text from " + table + " t where event_id = ?", event));
        }
        rows.addAll(texts("select t::text from event t where id = ?", event));
        rows.addAll(texts(
                "select t::text from group_member t join fight_group g on g.id = t.group_id where g.event_id = ?",
                event));
        rows.addAll(texts(
                "select t::text from match_event t join fight_match m on m.id = t.match_id where m.event_id = ?",
                event));
        return rows.stream().sorted().collect(Collectors.joining("\n"));
    }

    private List<String> texts(String sql, UUID event) {
        return jdbc.sql(sql).param(event).query(String.class).list();
    }

    private int call(Row row, Role role, Fixture fixture) throws Exception {
        var request = build(row, fixture.ids());
        var token = fixture.tokens().get(role);
        if (token != null) {
            request.header(HttpHeaders.AUTHORIZATION, "Bearer " + token);
        }
        if (role == Role.SUPERADMIN) {
            request.header(CloudflareAccess.HEADER, cloudflare.assertion());
        }
        return mvc.perform(request).andReturn().getResponse().getStatus();
    }

    /**
     * The row's request. Its last column: a JSON body; {@code ?a=b} a query; {@code bytes}, {@code csv} a file sent
     * as such; {@code multipart <part>} a form with a PDF in the part {@code file} or a text in any other.
     */
    private static AbstractMockHttpServletRequestBuilder<?> build(Row row, Map<String, String> ids) {
        var method = HttpMethod.valueOf(row.method());
        var path = fill(row.path(), ids);
        var spec = fill(row.body(), ids);
        if (spec.startsWith("multipart ")) {
            var part = spec.substring("multipart ".length());
            var form = multipart(method, path);
            return part.equals("file")
                    ? form.file(new MockMultipartFile("file", "reglamento.pdf", "application/pdf", PDF))
                    : form.param(part, "Ana Prueba 01/03/2021");
        }
        if (spec.equals("bytes") || spec.equals("csv")) {
            return request(method, path)
                    .contentType(spec.equals("csv") ? "text/csv" : MediaType.APPLICATION_OCTET_STREAM_VALUE)
                    .content("x".getBytes(StandardCharsets.UTF_8));
        }
        if (spec.startsWith("?")) {
            return request(method, path + spec).contentType(MediaType.APPLICATION_JSON);
        }
        var request = request(method, path).contentType(MediaType.APPLICATION_JSON);
        return spec.isEmpty() ? request : request.content(spec);
    }

    private static String fill(String text, Map<String, String> ids) {
        return VARIABLE.matcher(text)
                .replaceAll(m -> ids.getOrDefault(m.group(1), UUID.randomUUID().toString()));
    }

    /** A fresh demo event, started, with a group of four of 4-6 on a mat and four more people free. */
    private Fixture fixture() throws Exception {
        resetDatabaseClockAndEmails();
        eventId = demo.seed();
        startPhase(eventId);
        var ids = new HashMap<String, String>();
        ids.put("eventId", eventId.toString());
        var category = one("select id from event_category where event_id = ? and name = '4-6'", eventId);
        ids.put("categoryId", category);
        var people = new ArrayList<String>();
        for (int i = 0; i < 8; i++) {
            var participant = new Participant(eventId, clock.instant());
            participant.update("Peque" + i, "Prueba", LocalDate.of(2022, 3, 1), 110, true);
            people.add(participants.save(participant).getId().toString());
        }
        ids.put("participantId", people.get(0));
        ids.put("participant2", people.get(1));
        for (int i = 1; i <= 4; i++) {
            ids.put("free" + i, people.get(3 + i));
        }
        ids.put("personId", one("select person_id from participant where id = ?::uuid", people.get(0)));
        call(
                        post("/api/v1/events/" + eventId + "/groups").content("""
                                {"categoryId":"%s","groups":[{"participantIds":["%s","%s","%s","%s"]}]}""".formatted(
                                        category, people.get(0), people.get(1), people.get(2), people.get(3))),
                        "ayudante1")
                .andExpect(status().isCreated());
        ids.put("groupId", one("select id from fight_group where event_id = ?", eventId));
        ids.put("matchId", one("select id from fight_match where event_id = ? order by order_index limit 1", eventId));
        ids.put("matId", one("select mat_id from fight_group where event_id = ?", eventId));
        ids.put(
                "mat2Id",
                one(
                        "select id from mat where event_id = ? and id <> ?::uuid order by number limit 1",
                        eventId,
                        ids.get("matId")));
        teams(ids);
        ids.put("accountId", accountId("ayudante2").toString());
        ids.put("type", "terms");
        ids.put(
                "matReferees",
                jdbc
                        .sql("select referee_account_id from mat where event_id = ? order by number")
                        .param(eventId)
                        .query(UUID.class)
                        .list()
                        .stream()
                        .map(id -> id == null ? "null" : "\"" + id + "\"")
                        .collect(Collectors.joining(",", "[", "]")));
        call(post("/api/v1/events/" + eventId + "/invitations").content("""
                        {"email":"invitado@example.test","role":"GROUPER"}"""), "club1")
                .andExpect(status().is2xxSuccessful());
        ids.put("invitationId", one("select id from staff_invitation limit 1"));
        mvc.perform(multipart(HttpMethod.PUT, "/api/v1/events/" + eventId + "/rulebook")
                        .file(new MockMultipartFile("file", "reglamento.pdf", "application/pdf", PDF))
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + login("club1", "club1")))
                .andExpect(status().isOk());
        return new Fixture(ids, tokens(ids));
    }

    /** Two teams of 15-16, of three and of two, so one can take someone from the other. */
    private void teams(Map<String, String> ids) throws Exception {
        var category = one("select id from event_category where event_id = ? and name = '15-16'", eventId);
        var teens = new ArrayList<String>();
        for (int i = 0; i < 5; i++) {
            var participant = new Participant(eventId, clock.instant());
            participant.update("Mayor" + i, "Prueba", LocalDate.of(2012, 3, 1), 160, true);
            teens.add("\"" + participants.save(participant).getId() + "\"");
        }
        ids.put("teamMember", teens.get(0).replace("\"", ""));
        ids.put("teamId", team(category, String.join(",", teens.subList(0, 3))));
        ids.put("team2Id", team(category, String.join(",", teens.subList(3, 5))));
    }

    private String team(String category, String members) throws Exception {
        return JsonPath.read(
                call(
                                post("/api/v1/events/" + eventId + "/categories/" + category + "/teams")
                                        .content("{\"participantIds\":[%s]}".formatted(members)),
                                "club1")
                        .andExpect(status().isCreated())
                        .andReturn()
                        .getResponse()
                        .getContentAsString(),
                "$.id");
    }

    private Map<Role, String> tokens(Map<String, String> ids) throws Exception {
        var tokens = new EnumMap<Role, String>(Role.class);
        tokens.put(Role.CLUB, login("club1", "club1"));
        tokens.put(Role.GROUPER, login("ayudante1", "ayudante1"));
        // The referee of the group's mat; the temporary one referees another.
        var referee = one(
                "select a.email from mat m join account a on a.id = m.referee_account_id where m.id = ?::uuid",
                ids.get("matId"));
        tokens.put(Role.REFEREE, login(referee, referee));
        tokens.put(Role.OUTSIDER, login(outsider(), PASSWORD));
        var other = one("select number from mat where id = ?::uuid", ids.get("mat2Id"));
        var created = call(
                        post("/api/v1/events/" + eventId + "/temporary-access")
                                .content("{\"name\":\"Juan\",\"role\":\"REFEREE\",\"mat\":%s}".formatted(other)),
                        "club1")
                .andReturn()
                .getResponse()
                .getContentAsString();
        ids.put("accessId", one("select id from temporary_access limit 1"));
        String link = JsonPath.read(created, "$.link");
        tokens.put(
                Role.TEMPORARY,
                JsonPath.read(
                        mvc.perform(post("/api/v1/auth/temporary")
                                        .contentType(MediaType.APPLICATION_JSON)
                                        .content("{\"token\":\"%s\"}"
                                                .formatted(link.substring(link.indexOf("code=") + 5))))
                                .andReturn()
                                .getResponse()
                                .getContentAsString(),
                        "$.accessToken"));
        tokens.put(
                Role.SUPERADMIN,
                JsonPath.read(
                        mvc.perform(post("/api/v1/admin/auth/login")
                                        .header(CloudflareAccess.HEADER, cloudflare.assertion())
                                        .contentType(MediaType.APPLICATION_JSON)
                                        .content("{\"email\":\"%s\",\"password\":\"%s\"}"
                                                .formatted(SUPERADMIN_EMAIL, PASSWORD)))
                                .andReturn()
                                .getResponse()
                                .getContentAsString(),
                        "$.accessToken"));
        return tokens;
    }

    private String login(String email, String password) {
        return auth.login(email, password, "127.0.0.1").accessToken();
    }

    private String one(String sql, Object... params) {
        return String.valueOf(
                jdbc.sql(sql).params(Arrays.asList(params)).query().singleValue());
    }

    private static List<Row> rows() throws IOException {
        return Files.readAllLines(MATRIX, StandardCharsets.UTF_8).stream()
                .filter(l -> !l.isBlank() && !l.startsWith("#"))
                .map(Row::parse)
                .toList();
    }

    private static void write(List<Row> rows, Map<Row, Set<Role>> observed) throws IOException {
        var lines = new ArrayList<String>();
        for (var line : Files.readAllLines(MATRIX, StandardCharsets.UTF_8)) {
            if (line.isBlank() || line.startsWith("#")) {
                lines.add(line);
                continue;
            }
            var row = Row.parse(line);
            var seen = observed.entrySet().stream()
                    .filter(e -> e.getKey().key().equals(row.key()))
                    .findFirst();
            lines.add(seen.isPresent() ? row.format(seen.get().getValue()) : line);
        }
        Files.write(MATRIX, lines, StandardCharsets.UTF_8);
    }
}
