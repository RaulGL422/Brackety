package dev.rgal.brackety;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.AuthTestConfig;
import dev.rgal.brackety.common.MutableClock;
import io.zonky.test.db.postgres.embedded.EmbeddedPostgres;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.time.Duration;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import javax.sql.DataSource;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Test;
import org.postgresql.PGConnection;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * Server battery, «Migraciones» (docs/04-testing.md, GR-8): the hall's database of the last release, with the
 * yoseikan-f1 event in use (phase started, groups, teams, finished matches, one in progress, a QR access), is updated
 * to this version the way the server does on start (Flyway), and the day goes on: nothing is lost and the club,
 * the referees and the downloads work on it. The data comes from {@code tools/MigrationSnapshot.java}, run at each
 * release; from zero, every other test already migrates an empty database.
 */
@SpringBootTest(
        properties = {
            "brackety.rate-limit.per-minute=100000",
            "brackety.rate-limit.auth-per-minute=100000",
            "brackety.auth.unverified-purge-initial-delay=P3650D",
            "brackety.auth.deleted-purge-initial-delay=P3650D"
        })
@AutoConfigureMockMvc
@Import({AuthTestConfig.class, MigrationFromReleaseTest.ReleaseDatabase.class})
class MigrationFromReleaseTest {

    private static final String SNAPSHOT = "/migration/release/";
    private static final Map<String, Long> LOADED = new LinkedHashMap<>();
    private static EmbeddedPostgres postgres;

    @Autowired
    MockMvc mvc;

    @Autowired
    JdbcClient jdbc;

    @Autowired
    AuthService auth;

    @Autowired
    MutableClock clock;

    /** The release's schema with its data, before Spring's Flyway brings it to this version. */
    @TestConfiguration(proxyBeanMethods = false)
    static class ReleaseDatabase {

        @Bean
        @Primary
        DataSource releaseDataSource() throws IOException, SQLException {
            postgres = EmbeddedPostgres.builder().start();
            var dataSource = postgres.getPostgresDatabase();
            var snapshot = resource("release.txt").lines().toList();
            Flyway.configure()
                    .dataSource(dataSource)
                    .locations("classpath:db/migration")
                    .target(snapshot.get(1))
                    .load()
                    .migrate();
            try (var connection = dataSource.getConnection()) {
                connection.setAutoCommit(false);
                // Rows in file order, not in the order their keys need.
                connection.createStatement().execute("set session_replication_role = replica");
                var copy = connection.unwrap(PGConnection.class).getCopyAPI();
                for (var table : snapshot.subList(2, snapshot.size())) {
                    var csv = resource(table + ".csv");
                    var columns = csv.lines().findFirst().orElseThrow();
                    LOADED.put(
                            table,
                            copy.copyIn(
                                    "copy " + table + " (" + columns + ") from stdin with (format csv, header)",
                                    new InputStreamReader(
                                            new java.io.ByteArrayInputStream(csv.getBytes(StandardCharsets.UTF_8)),
                                            StandardCharsets.UTF_8)));
                }
                connection.commit();
            }
            return dataSource;
        }
    }

    @AfterAll
    static void stop() throws IOException {
        postgres.close();
    }

    @Test
    void everyRowOfTheReleaseIsStillThere() {
        assertThat(LOADED).isNotEmpty();
        var tables = jdbc.sql("select tablename from pg_tables where schemaname = 'public'")
                .query(String.class)
                .list();
        LOADED.forEach((table, rows) -> {
            assertThat(tables).as("table %s", table).contains(table);
            assertThat(jdbc.sql("select count(*) from " + table)
                            .query(Long.class)
                            .single())
                    .as("rows of %s", table)
                    .isEqualTo(rows);
        });
        assertThat(LOADED.get("fight_match")).isPositive();
    }

    // The update lands in the middle of the day: the referee ends the match left open, the next one
    // starts, the club sees standings and downloads, and finishes the phase.
    @Test
    void theDayGoesOnAfterTheUpdate() throws Exception {
        var event = jdbc.sql("select id from event order by created_at limit 1")
                .query(UUID.class)
                .single();
        // The update took an hour: the same day, after the last match the hall played.
        var lastFinish = jdbc.sql("select max(finished_at) from fight_match")
                .query(Instant.class)
                .single();
        clock.set(lastFinish.plus(Duration.ofHours(1)));

        var running = jdbc.sql("select id from fight_match where status = 'IN_PROGRESS'")
                .query(UUID.class)
                .single();
        // Its time ran out meanwhile: the referee ends it with the score it had.
        act("arbitro2", running, "{\"type\":\"FINISH\"");

        var mat1 = jdbc.sql("select id from mat where event_id = ? and number = 1")
                .param(event)
                .query(UUID.class)
                .single();
        String next = JsonPath.read(body("arbitro1", get("/api/v1/mats/" + mat1 + "/board")), "$.recommendedMatchId");
        assertThat(next).isNotNull();
        act("arbitro1", UUID.fromString(next), "{\"type\":\"START\"");
        act(
                "arbitro1",
                UUID.fromString(next),
                "{\"type\":\"DISQUALIFICATION\",\"side\":\"BLUE\",\"reason\":\"Prueba\"");
        act("arbitro1", UUID.fromString(next), "{\"type\":\"FINISH\"");

        List<Object> standings = JsonPath.read(body("club1", get(events(event, "/standings"))), "$");
        assertThat(standings).hasSize(rows("select count(*) from participant where event_id = '" + event + "'"));
        assertThat(body("club1", get(events(event, "/export/matches.csv"))).lines())
                .hasSize(rows("select count(*) from fight_match") + 1);
        body("club1", get(events(event, "/export/package")));
        body("club1", post(events(event, "/phase/finish")));
    }

    private void act(String referee, UUID match, String action) throws Exception {
        var known = rows("select count(*) from match_event where match_id = '" + match + "' and not automatic");
        body(referee, post("/api/v1/matches/" + match + "/events").content(action + ",\"knownEvents\":" + known + "}"));
    }

    private String body(String username, MockHttpServletRequestBuilder request) throws Exception {
        var token = auth.login(username, username, "127.0.0.1").accessToken();
        var response = mvc.perform(request.header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON))
                .andReturn()
                .getResponse();
        assertThat(response.getStatus()).as(response.getContentAsString()).isBetween(200, 299);
        return response.getContentAsString();
    }

    private int rows(String sql) {
        return jdbc.sql(sql).query(Integer.class).single();
    }

    private static String events(UUID event, String path) {
        return "/api/v1/events/" + event + path;
    }

    private static String resource(String name) {
        try (var in = MigrationFromReleaseTest.class.getResourceAsStream(SNAPSHOT + name)) {
            if (in == null) {
                throw new IllegalStateException("No " + SNAPSHOT + name + ": run tools/MigrationSnapshot.java");
            }
            return new String(in.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
