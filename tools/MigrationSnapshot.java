import java.io.FileWriter;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;
import org.postgresql.PGConnection;

/**
 * The data of the last release for the migration test (docs/04-testing.md, «Migraciones»). Run at each release
 * against that release's local server with the yoseikan-f1 scenario: it uses the event through the API as on a
 * competition day (phase started, groups, teams, finished matches, one in progress, a QR access) and copies every
 * table to a CSV. Steps in docs/04-testing.md.
 *
 * <pre>
 * java -cp postgresql.jar tools/MigrationSnapshot.java http://localhost:8093 jdbc:postgresql://localhost:15434/postgres \
 *     server/src/test/resources/migration/release v0.8.2
 * </pre>
 */
public class MigrationSnapshot {

    private static final HttpClient HTTP = HttpClient.newHttpClient();
    private static final Pattern RECOMMENDED = Pattern.compile("\"recommendedMatchId\":\"([^\"]+)\"");
    private static final Pattern PERSON = Pattern.compile("\\{\"id\":\"([0-9a-f-]{36})\"");
    private static final Pattern ACCESS = Pattern.compile("\"accessToken\":\"([^\"]+)\"");

    private final String api;
    private final Connection db;

    MigrationSnapshot(String api, Connection db) {
        this.api = api;
        this.db = db;
    }

    public static void main(String[] args) throws Exception {
        try (var db = DriverManager.getConnection(args[1], "postgres", "")) {
            var snapshot = new MigrationSnapshot(args[0], db);
            snapshot.useTheEvent();
            snapshot.dump(Path.of(args[2]), args[3]);
        }
    }

    void useTheEvent() throws Exception {
        var club = login("club1");
        var event = single("select id from event order by created_at limit 1");
        send(club, "POST", "/api/v1/events/" + event + "/phase/start", "");
        // Two individual groups on mats 1 and 2, and up to two teams of the largest team category. People belong to
        // a category by age, so the event's screen lists them.
        var individual = new ArrayList<List<String>>();
        for (var category : list("select id from event_category where team_size is null order by min_age")) {
            var people = categoryPeople(club, event, category);
            if (people.size() >= 4 && individual.size() < 2) {
                individual.add(List.of(category, quoted(people.subList(0, 4))));
            }
        }
        for (int i = 0; i < individual.size(); i++) {
            var mat = single("select id from mat where event_id = '" + event + "' and number = " + (i + 1));
            send(club, "POST", "/api/v1/events/" + event + "/groups", """
                    {"categoryId":"%s","groups":[{"participantIds":[%s]}],"matId":"%s"}"""
                    .formatted(individual.get(i).get(0), individual.get(i).get(1), mat));
        }
        String teamCategory = null;
        var teamPeople = List.<String>of();
        for (var category : list("select id from event_category where team_size = 3 order by min_age")) {
            var people = categoryPeople(club, event, category);
            if (people.size() > teamPeople.size()) {
                teamCategory = category;
                teamPeople = people.subList(0, Math.min(6, people.size()));
            }
        }
        for (int i = 0; i < teamPeople.size() / 3; i++) {
            send(club, "POST", "/api/v1/events/" + event + "/categories/" + teamCategory + "/teams", """
                    {"participantIds":[%s]}""".formatted(quoted(teamPeople.subList(3 * i, 3 * i + 3))));
        }
        send(club, "POST", "/api/v1/events/" + event + "/temporary-access", """
                {"name":"Lucía","role":"GROUPER"}""");
        // Mat 1 plays three matches, mat 2 two and leaves the third in progress.
        play(login("arbitro1"), 1, 3, false);
        play(login("arbitro2"), 2, 2, true);
    }

    // A disqualification ends a match at once: no waiting for its clock.
    private void play(String referee, int mat, int finished, boolean leaveOneRunning) throws Exception {
        var matId = single("select id from mat where number = " + mat);
        for (int i = 0; i < finished; i++) {
            var match = recommended(referee, matId);
            act(referee, match, "{\"type\":\"START\"");
            act(referee, match, "{\"type\":\"POINT\",\"side\":\"RED\"");
            act(referee, match, "{\"type\":\"POINT\",\"side\":\"BLUE\"");
            act(referee, match, "{\"type\":\"POINT\",\"side\":\"RED\"");
            act(referee, match, "{\"type\":\"DISQUALIFICATION\",\"side\":\"BLUE\",\"reason\":\"Prueba\"");
            act(referee, match, "{\"type\":\"FINISH\"");
        }
        if (leaveOneRunning) {
            var match = recommended(referee, matId);
            act(referee, match, "{\"type\":\"START\"");
            act(referee, match, "{\"type\":\"POINT\",\"side\":\"BLUE\"");
        }
    }

    // What the referee's screen offers next; while the fighters have their least rest, it waits like they would.
    private String recommended(String referee, String matId) throws Exception {
        var board = "";
        for (int attempt = 0; attempt < 30; attempt++) {
            board = send(referee, "GET", "/api/v1/mats/" + matId + "/board", "");
            var match = RECOMMENDED.matcher(board);
            if (match.find()) {
                return match.group(1);
            }
            Thread.sleep(5_000);
        }
        throw new IllegalStateException("Nothing recommended on mat " + matId + " for 150 s: " + board);
    }

    private List<String> categoryPeople(String club, String event, String category) throws Exception {
        var people = PERSON.matcher(
                send(club, "GET", "/api/v1/events/" + event + "/categories/" + category + "/participants", ""));
        var ids = new ArrayList<String>();
        while (people.find()) {
            ids.add(people.group(1));
        }
        return ids;
    }

    private void act(String referee, String match, String action) throws Exception {
        var known = single("select count(*) from match_event where match_id = '" + match + "' and not automatic");
        send(referee, "POST", "/api/v1/matches/" + match + "/events", action + ",\"knownEvents\":" + known + "}");
    }

    void dump(Path dir, String release) throws Exception {
        Files.createDirectories(dir);
        try (var old = Files.list(dir)) {
            for (var file : old.toList()) {
                Files.delete(file);
            }
        }
        var tables = list("select tablename from pg_tables where schemaname = 'public'"
                + " and tablename <> 'flyway_schema_history' order by tablename");
        var copy = db.unwrap(PGConnection.class).getCopyAPI();
        for (var table : tables) {
            try (var out = new FileWriter(dir.resolve(table + ".csv").toFile(), StandardCharsets.UTF_8)) {
                copy.copyOut("copy " + table + " to stdout with (format csv, header)", out);
            }
        }
        var version = single("select version from flyway_schema_history where success and version is not null"
                + " order by installed_rank desc limit 1");
        Files.writeString(dir.resolve("release.txt"), release + "\n" + version + "\n" + String.join("\n", tables) + "\n");
    }

    private String login(String username) throws Exception {
        var body = send(null, "POST", "/api/v1/auth/login", """
                {"email":"%s","password":"%s"}""".formatted(username, username));
        var token = ACCESS.matcher(body);
        if (!token.find()) {
            throw new IllegalStateException("No access token for " + username + ": " + body);
        }
        return token.group(1);
    }

    private String send(String token, String method, String path, String body) throws Exception {
        var request = HttpRequest.newBuilder(URI.create(api + path))
                .header("Content-Type", "application/json")
                .method(method, body.isEmpty() ? HttpRequest.BodyPublishers.noBody() : HttpRequest.BodyPublishers.ofString(body));
        if (token != null) {
            request.header("Authorization", "Bearer " + token);
        }
        var response = HTTP.send(request.build(), HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() >= 300) {
            throw new IllegalStateException(method + " " + path + " " + response.statusCode() + ": " + response.body());
        }
        return response.body();
    }

    private List<String> list(String sql) throws Exception {
        var values = new ArrayList<String>();
        try (var statement = db.createStatement();
                var rows = statement.executeQuery(sql)) {
            while (rows.next()) {
                values.add(rows.getString(1));
            }
        }
        return values;
    }

    private String single(String sql) throws Exception {
        var values = list(sql);
        if (values.size() != 1) {
            throw new IllegalStateException(values.size() + " rows for " + sql);
        }
        return values.getFirst();
    }

    private static String quoted(List<String> ids) {
        return String.join(",", ids.stream().map(id -> "\"" + id + "\"").toList());
    }
}
