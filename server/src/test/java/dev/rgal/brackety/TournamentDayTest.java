package dev.rgal.brackety;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.event.EventApiTest;
import dev.rgal.brackety.event.TestSports;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.stream.LongStream;
import java.util.stream.Stream;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import tools.jackson.databind.json.JsonMapper;

/**
 * Server battery, «Día completo» (docs/04-testing.md, GR-8): a tournament through the real API from the club
 * enrolling people to the downloads, with the incidents of a real day on the way: a mat disabled and back, a QR
 * referee who loses the session and signs in again with the temporary user and password, a device action that
 * clashes and goes to the club's review, a finished match reopened to correct it, and the phase finished, reopened
 * and finished again. Groups of 3 to 5, one category with the return leg. Fixed seeds, so a failure repeats.
 *
 * <p>At the end: every match played, each score equal to what the referees pressed, and the standings, their CSV
 * and the matches CSV telling the same story. A league runs the day once per phase.
 */
class TournamentDayTest extends EventApiTest {

    private static final Duration TICK = Duration.ofSeconds(10);
    private static final int MATCH_TICKS = 3;
    private static final String CHILDREN = "9-10";
    private static final String TEENS = "13-14";
    // By teams of 3 in the demo event.
    private static final String TEAMS = "15-16";
    private static final List<Integer> MATS = List.of(1, 2, 3);
    private static final int QR_MAT = 2;
    private static final int DISABLED_MAT = 3;

    @Autowired
    JsonMapper json;

    // One seed per sport on every pull request; a release runs the five the battery asks for (-Dbattery.seeds=5).
    static Stream<Arguments> days() {
        var seeds = Long.getLong("battery.seeds", 1);
        return Stream.of("TAMBO", "GRAPPLING")
                .flatMap(sport -> LongStream.rangeClosed(1, seeds).mapToObj(seed -> Arguments.of(sport, seed)));
    }

    @ParameterizedTest(name = "{0}, seed {1}")
    @MethodSource("days")
    void aWholeTournamentWithIncidentsEndsCoherent(String sport, long seed) throws Exception {
        new Day(sport.equals("GRAPPLING"), new Random(seed), eventId, null, false).run();
    }

    /**
     * A day with a category by teams of 3 beside the individual one: the club makes the teams, groups of 3 to 5
     * teams, and their matches go to the pool, where any free mat takes them, through the same incidents.
     */
    @ParameterizedTest(name = "seed {0}")
    @MethodSource("leagueSeeds")
    void aDayWithTeamsEndsCoherent(long seed) throws Exception {
        new Day(false, new Random(seed), eventId, null, true).run();
    }

    static LongStream leagueSeeds() {
        return LongStream.rangeClosed(1, Long.getLong("battery.seeds", 1));
    }

    /**
     * A league of two phases: four weeks after the first day the club opens the second phase from it, enters the
     * same people again, and lives another whole day with its incidents. The league's standings, their downloads and
     * each person's record add both days up.
     */
    @ParameterizedTest(name = "seed {0}")
    @MethodSource("leagueSeeds")
    void aLeagueOfTwoPhasesAddsUpBothDays(long seed) throws Exception {
        var random = new Random(seed);
        new Day(false, random, eventId, null, false).run();
        var date = jdbc.sql("select event_date from event where id = ?")
                .param(eventId)
                .query(LocalDate.class)
                .single()
                .plusWeeks(4);
        var created = call(post("/api/v1/events/" + eventId + "/league/phases").content("""
                                {"name":"Fase 2","date":"%s","discipline":"TAMBO","attendancePoints":10}""".formatted(date)), "club1")
                .andReturn()
                .getResponse()
                .getContentAsString();
        var second = UUID.fromString(JsonPath.read(created, "$.eventId"));
        clock.set(date.atTime(9, 0).atZone(clock.getZone()).toInstant());
        new Day(false, random, second, eventId, false).run();

        checkTheLeague(List.of(eventId, second));
    }

    private void checkTheLeague(List<UUID> phases) throws Exception {
        var last = phases.getLast();
        // Each phase's own standings: person → total there.
        var phaseTotals = new ArrayList<Map<String, Integer>>();
        for (var phase : phases) {
            List<Map<String, Object>> rows = JsonPath.read(read("/api/v1/events/" + phase + "/standings"), "$");
            phaseTotals.add(rows.stream()
                    .collect(Collectors.toMap(row -> (String) row.get("personId"), row -> (Integer) row.get("total"))));
        }
        List<Map<String, Object>> rows = JsonPath.read(read("/api/v1/events/" + last + "/league/standings"), "$.rows");
        var people = countOf("select count(distinct person_id) from participant where event_id in ('" + phases.get(0)
                + "', '" + last + "')");
        assertThat(rows).hasSize(people);
        for (var row : rows) {
            var person = (String) row.get("personId");
            @SuppressWarnings("unchecked")
            var points = (List<Map<String, Integer>>) row.get("phases");
            var sum = 0;
            for (int i = 0; i < phases.size(); i++) {
                var phase = points.get(i);
                assertThat(phase).as("phase %d of %s", i + 1, person).isNotNull();
                var total = phase.get("attendancePoints") + phase.get("matchPoints");
                assertThat(total)
                        .as("phase %d of %s, as in that phase's standings", i + 1, person)
                        .isEqualTo(phaseTotals.get(i).get(person));
                sum += total;
            }
            assertThat(row.get("total")).as("league total of %s", person).isEqualTo(sum);
        }

        var csv = lines(read("/api/v1/events/" + last + "/export/league-standings.csv"));
        assertThat(csv).hasSize(rows.size() + 1);
        for (int i = 0; i < rows.size(); i++) {
            assertThat(csv.get(i + 1))
                    .as("line %d of league-standings.csv", i + 1)
                    .contains(
                            ";" + rows.get(i).get("firstName") + ";",
                            ";" + rows.get(i).get("total") + ";");
        }
        read("/api/v1/events/" + last + "/export/league-standings.pdf");
        read("/api/v1/events/" + last + "/export/league-standings-by-category.zip");

        // Someone's record: both phases, with every match they fought in each.
        var person = (String) rows.getFirst().get("personId");
        var record = read("/api/v1/events/" + last + "/league/people/" + person + "/record");
        List<Integer> matches = JsonPath.read(record, "$.phases[*].matches.length()");
        assertThat(matches).hasSize(phases.size());
        assertThat(matches.stream().mapToInt(Integer::intValue).sum())
                .isEqualTo(countOf("select count(*) from fight_match f join participant p"
                        + " on p.id in (f.red_participant_id, f.blue_participant_id)"
                        + " where f.status = 'FINISHED' and p.person_id = '" + person + "'"));
    }

    private String read(String path) throws Exception {
        var response = call(get(path), "club1").andReturn().getResponse();
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        assertThat(response.getStatus()).as(path).isEqualTo(200);
        return response.getContentAsString();
    }

    private final class Day {

        private final boolean grappling;
        private final Random random;
        private final Map<String, String> tokens = new HashMap<>();
        private final Map<Integer, Running> running = new HashMap<>();
        // What the referees really pressed: match → [red, blue].
        private final Map<String, int[]> pressed = new HashMap<>();
        private final Map<String, Integer> seen = new LinkedHashMap<>();
        private final List<String> log = new ArrayList<>();
        private final UUID event;
        // The second category is by teams instead of the teens'.
        private final boolean teams;
        // The phase before, in a league: its people enter this one again.
        private final UUID previous;
        private final List<Planned> laterGroups = new ArrayList<>();
        private String qrUser;
        private String qrPassword;
        private String qrRefresh;
        private int expectedMatches;
        private int tick;
        private int idleTicks;

        Day(boolean grappling, Random random, UUID event, UUID previous, boolean teams) {
            this.grappling = grappling;
            this.teams = teams;
            this.random = random;
            this.event = event;
            this.previous = previous;
        }

        void run() throws Exception {
            setUp();
            enrol();
            call("club1", post(events("/phase/start"))).expectOk();
            qrReferee();
            makeGroups();
            for (tick = 0; tick < 1000 && !dayOver(); tick++) {
                if (tick == 10) {
                    laterGroups.forEach(g -> createGroup(g.category(), g.people()));
                    laterGroups.clear();
                }
                incidents();
                for (var mat : MATS) {
                    step(mat);
                }
                checkNotStalled();
                clock.advance(TICK);
                if (tick % 30 == 0) {
                    tokens.clear();
                }
            }
            assertThat(dayOver()).as("the day stalled: %s", log).isTrue();
            assertThat(seen)
                    .as("what the day went through")
                    .containsKeys("mat disabled", "mat enabled", "QR signed in again", "review", "match reopened");
            phaseReopened();
            checkTheEnd();
        }

        private void setUp() {
            jdbc.sql("delete from mat where number > 3 and event_id = ?")
                    .param(event)
                    .update();
            jdbc.sql("update event set started_at = null where id = ?")
                    .param(event)
                    .update();
            jdbc.sql("update modality set min_rest_seconds = 20, changeover_seconds = 0")
                    .update();
            jdbc.sql("update modality_rules set match_seconds = 25, points_limit = 0")
                    .update();
            if (grappling) {
                jdbc.sql("update modality set scoring = ?::jsonb where event_id = ?")
                        .params(json.writeValueAsString(TestSports.GRAPPLING), event)
                        .update();
            }
            // GR-5: groups of 3 to 5; the teens fight each other twice, with the colours changed.
            jdbc.sql("update event_category set min_group_size = 3, max_group_size = 5, return_leg = (name = ?)"
                            + " where name in (?, ?, ?) and event_id = ?")
                    .params(TEENS, CHILDREN, TEENS, TEAMS, event)
                    .update();
        }

        // The club enrols everyone through the import, as from the spreadsheet; in a league's next phase, it enters
        // the people of the phase before again.
        private void enrol() throws Exception {
            if (previous != null) {
                var people = jdbc.sql("select person_id::text from participant where event_id = ?")
                        .param(previous)
                        .query(String.class)
                        .list();
                call(
                                "club1",
                                post(events("/league/reenrol"))
                                        .content("{\"personIds\":[" + quoted(people) + "],\"guardianConsent\":true}"))
                        .expectOk();
                return;
            }
            var date = jdbc.sql("select event_date from event where id = ?")
                    .param(event)
                    .query(LocalDate.class)
                    .single();
            var rows = new ArrayList<String>();
            for (var category : categories()) {
                int age = Map.of(CHILDREN, 10, TEENS, 14, TEAMS, 16).get(category);
                // Teams: 4 or 5 teams of 3.
                int people = category.equals(TEAMS) ? 3 * (4 + random.nextInt(2)) : 9 + random.nextInt(6);
                for (int i = 0; i < people; i++) {
                    rows.add("""
                            {"firstName":"%s%d","lastName":"Prueba","birthDate":"%s","sex":"%s","categoryId":"%s"}""".formatted(
                                    category.equals(CHILDREN) ? "Nino" : "Joven",
                                    i,
                                    date.minusYears(age).minusDays(1 + i),
                                    i % 2 == 0 ? "MALE" : "FEMALE",
                                    categoryId(category)));
                }
            }
            call("club1", post(events("/participants/import")).content("""
                            {"rows":[%s],"consentVersion":"v1"}""".formatted(String.join(",", rows))))
                    .expect(201);
        }

        // Mat 2's referee comes by QR, as at the grappling.
        private void qrReferee() throws Exception {
            var created = call("club1", post(events("/temporary-access")).content("""
                            {"name":"Juan","role":"REFEREE","mat":%d}""".formatted(QR_MAT)))
                    .expect(201)
                    .body();
            qrUser = JsonPath.read(created, "$.signIn");
            qrPassword = JsonPath.read(created, "$.password");
            String link = JsonPath.read(created, "$.link");
            var signedIn = anonymous(post("/api/v1/auth/temporary")
                            .content("""
                            {"token":"%s"}""".formatted(link.substring(link.indexOf("code=") + 5))))
                    .expect(200)
                    .body();
            keepQrSession(signedIn);
        }

        // Each category split into groups of 3 to 5 (people, or teams of 3 people); one of each comes later.
        private void makeGroups() throws Exception {
            for (var category : categories()) {
                // As the screen lists them: by age, also those entered again without a category of their own.
                List<String> listed = JsonPath.read(
                        call("club1", get(events("/categories/" + categoryId(category) + "/participants")))
                                .expect(200)
                                .body(),
                        "$[*].id");
                var people = new ArrayList<>(listed);
                Collections.shuffle(people, random);
                if (category.equals(TEAMS)) {
                    people = makeTeams(people);
                }
                var groups = new ArrayList<List<String>>();
                while (!people.isEmpty()) {
                    int size = people.size() <= 5 ? people.size() : 3 + random.nextInt(3);
                    if (people.size() - size > 0 && people.size() - size < 3) {
                        size = people.size() - 3;
                    }
                    groups.add(new ArrayList<>(people.subList(0, size)));
                    people.subList(0, size).clear();
                }
                laterGroups.add(new Planned(categoryId(category), groups.removeLast()));
                groups.forEach(g -> createGroup(categoryId(category), g));
            }
        }

        private ArrayList<String> makeTeams(List<String> people) throws Exception {
            var teamIds = new ArrayList<String>();
            for (int i = 0; i + 3 <= people.size(); i += 3) {
                var team = call(
                                "club1",
                                post(events("/categories/" + categoryId(TEAMS) + "/teams"))
                                        .content("{\"participantIds\":[" + quoted(people.subList(i, i + 3)) + "]}"))
                        .expect(201)
                        .body();
                teamIds.add(JsonPath.read(team, "$.id"));
            }
            log(teamIds.size() + " teams");
            return teamIds;
        }

        private List<String> categories() {
            return List.of(CHILDREN, teams ? TEAMS : TEENS);
        }

        // People, or the teams of a team category; team matches go to the pool, so no mat is chosen.
        private void createGroup(UUID category, List<String> people) {
            var ofTeams = teams && category.equals(categoryId(TEAMS));
            var mat = matId(MATS.get(random.nextInt(MATS.size())));
            var disabled = jdbc.sql("select disabled_at is not null from mat where id = ?")
                    .param(mat)
                    .query(Boolean.class)
                    .single();
            try {
                // A helper or the club.
                call(
                                random.nextBoolean() ? "ayudante1" : "club1",
                                post(events("/groups")).content("""
                                {"categoryId":"%s","groups":[{"%s":[%s]}],"matId":%s}""".formatted(
                                                category,
                                                ofTeams ? "teamIds" : "participantIds",
                                                quoted(people),
                                                disabled || ofTeams ? "null" : "\"" + mat + "\"")))
                        .expect(201);
            } catch (Exception e) {
                throw new IllegalStateException(e);
            }
            int pairs = people.size() * (people.size() - 1) / 2;
            expectedMatches += category.equals(categoryId(TEENS)) ? 2 * pairs : pairs;
            log("group of " + people.size() + (ofTeams ? " teams" : ""));
        }

        private void incidents() throws Exception {
            var finished = countOf(
                    "select count(*) from fight_match where status = 'FINISHED' and event_id = '" + event + "'");
            var progress = expectedMatches == 0 ? 0 : 100 * finished / expectedMatches;
            if (progress >= 20 && !seen.containsKey("mat disabled") && !running.containsKey(DISABLED_MAT)) {
                // Mat 3 breaks: its groups go to the mat that frees first.
                call(
                                "club1",
                                post(events("/control/mats/" + matId(DISABLED_MAT) + "/disable"))
                                        .content("{\"groupMats\":{}}"))
                        .expectOk();
                seen.put("mat disabled", tick);
                log("mat 3 disabled");
            }
            if (progress >= 70 && seen.containsKey("mat disabled") && !seen.containsKey("mat enabled")) {
                call("club1", post(events("/control/mats/" + matId(DISABLED_MAT) + "/enable")))
                        .expectOk();
                seen.put("mat enabled", tick);
                log("mat 3 back");
            }
            if (progress >= 35 && !seen.containsKey("QR signed in again")) {
                // The phone drops the session; the referee types the user and password the club gave them.
                qrRefresh = null;
                tokens.remove(qrUser);
                keepQrSession(anonymous(post("/api/v1/auth/login").content("""
                                {"email":"%s","password":"%s"}""".formatted(qrUser, qrPassword)))
                        .expect(200)
                        .body());
                seen.put("QR signed in again", tick);
                log("QR referee signed in again");
            }
        }

        private void step(int mat) throws Exception {
            if (isDisabled(mat)) {
                return;
            }
            var current = running.get(mat);
            if (current != null) {
                if (current.inReview()) {
                    review(mat, current);
                } else if (tick >= current.endTick()) {
                    finish(mat, current.match());
                    running.remove(mat);
                } else if (!seen.containsKey("review") && mat == 1 && tick > current.endTick() - 2) {
                    clash(mat, current);
                } else {
                    point(mat, current.match());
                }
                return;
            }
            if (!seen.containsKey("match reopened") && seen.containsKey("QR signed in again") && reopen(mat)) {
                return;
            }
            String recommended = JsonPath.read(board(mat), "$.recommendedMatchId");
            if (recommended == null) {
                return;
            }
            act(mat, recommended, "{\"type\":\"START\"").expect(200);
            pressed.put(recommended, new int[2]);
            running.put(mat, new Running(recommended, tick + MATCH_TICKS, false));
            log("start " + recommended + " on " + mat);
        }

        private void point(int mat, String match) throws Exception {
            var side = random.nextBoolean() ? 0 : 1;
            var value = grappling ? 1 + random.nextInt(4) : 1;
            if (random.nextInt(4) == 0 && pressed.get(match)[side] >= value) {
                // The referee takes back a point given by mistake.
                act(
                                mat,
                                match,
                                "{\"type\":\"POINT_REMOVED\",\"side\":\"%s\",\"points\":%d"
                                        .formatted(side(side), value))
                        .expect(200);
                pressed.get(match)[side] -= value;
            } else {
                act(mat, match, "{\"type\":\"POINT\",\"side\":\"%s\",\"points\":%d".formatted(side(side), value))
                        .expect(200);
                pressed.get(match)[side] += value;
            }
        }

        // Grappling ends a draw in the extra time; tambo keeps it.
        private void finish(int mat, String match) throws Exception {
            var view = call(referee(mat), get("/api/v1/matches/" + match))
                    .expect(200)
                    .body();
            if (Boolean.TRUE.equals(JsonPath.read(view, "$.needsExtraTime"))) {
                act(mat, match, "{\"type\":\"EXTRA_TIME\",\"side\":\"%s\"".formatted(side(random.nextInt(2))))
                        .expect(200);
            }
            act(mat, match, "{\"type\":\"FINISH\"").expect(200);
            log("finish " + match);
        }

        // The phone sends a point it scored without signal, but the web had moved on: the match waits for the club.
        private void clash(int mat, Running current) throws Exception {
            var stale = knownEvents(UUID.fromString(current.match())) - 1;
            var answer = call(
                    referee(mat),
                    post("/api/v1/matches/" + current.match() + "/events")
                            .content("""
                            {"type":"POINT","side":"RED","points":1,"opId":"%s","at":"%s","knownEvents":%d}""".formatted(UUID.randomUUID(), clock.instant(), stale)));
            assertThat(answer.status()).as(answer.body()).isEqualTo(409);
            running.put(mat, new Running(current.match(), current.endTick(), true));
            seen.put("review", tick);
            log("clash on " + current.match());
        }

        private void review(int mat, Running current) throws Exception {
            // The referee cannot go on until the club decides.
            act(mat, current.match(), "{\"type\":\"POINT\",\"side\":\"BLUE\",\"points\":1")
                    .expect(409);
            var apply = random.nextBoolean();
            var answer = call(
                            "club1",
                            post("/api/v1/matches/" + current.match() + "/review")
                                    .content("""
                            {"action":"%s"}""".formatted(apply ? "APPLY" : "DISCARD")))
                    .expect(200)
                    .body();
            if (apply) {
                assertThat((Integer) JsonPath.read(answer, "$.applied")).isEqualTo(1);
                pressed.get(current.match())[0] += 1;
            }
            running.put(mat, new Running(current.match(), tick + 1, false));
            log("review " + (apply ? "applied" : "discarded"));
        }

        // A referee reopens the last match of their mat with points to correct it.
        private boolean reopen(int mat) throws Exception {
            var last = jdbc.sql(LAST_WITH_POINTS)
                    .param(matId(mat))
                    .query(String.class)
                    .optional();
            if (last.isEmpty()) {
                return false;
            }
            var match = last.get();
            var reopened = act(mat, match, "{\"type\":\"REOPEN\",\"reason\":\"Punto sin anotar\"");
            if (reopened.status() == 409) {
                // Someone of it is fighting on another mat: the referee waits.
                return false;
            }
            reopened.expect(200);
            correct(mat, match);
            finish(mat, match);
            seen.put("match reopened", tick);
            return true;
        }

        // The phase ends, the club sees a mistake, reopens it, a referee corrects a match, and it ends again.
        private void phaseReopened() throws Exception {
            call("club1", post(events("/phase/finish"))).expectOk();
            call("club1", post(events("/phase/reopen")).content("{\"reason\":\"Corrección\"}"))
                    .expectOk();
            tokens.clear();
            var mat = 1;
            var match = jdbc.sql(LAST_WITH_POINTS)
                    .param(matId(mat))
                    .query(String.class)
                    .single();
            act(mat, match, "{\"type\":\"REOPEN\",\"reason\":\"Fase reabierta\"")
                    .expect(200);
            correct(mat, match);
            finish(mat, match);
            call("club1", post(events("/phase/finish"))).expectOk();
        }

        // Tambo takes a forgotten point after the time (F1-3); grappling does not, so there a point comes off.
        private void correct(int mat, String match) throws Exception {
            var score = pressed.get(match);
            if (!grappling) {
                act(mat, match, "{\"type\":\"POINT\",\"side\":\"BLUE\",\"points\":1")
                        .expect(200);
                score[1] += 1;
                return;
            }
            var side = score[0] > 0 ? 0 : 1;
            act(mat, match, "{\"type\":\"POINT_REMOVED\",\"side\":\"%s\",\"points\":1".formatted(side(side)))
                    .expect(200);
            score[side] -= 1;
        }

        private void checkTheEnd() throws Exception {
            assertThat(countOf("select count(*) from fight_match where event_id = '" + event + "'"))
                    .isEqualTo(expectedMatches);
            assertThat(countOf("select count(*) from fight_match where event_id = '" + event
                            + "' and (status <> 'FINISHED' or review_reason is not null)"))
                    .as("matches not played: %s", log)
                    .isZero();
            assertThat(pressed).hasSize(expectedMatches);
            if (teams) {
                assertThat(countOf("select count(*) from fight_match where red_team_id is not null and event_id = '"
                                + event + "'"))
                        .as("team matches played")
                        .isPositive();
            }
            // Each score is what the referees pressed.
            jdbc.sql("select id::text, red_score, blue_score from fight_match where event_id = ?")
                    .param(event)
                    .query((rs, n) -> {
                        var match = rs.getString(1);
                        assertThat(new int[] {rs.getInt(2), rs.getInt(3)})
                                .as("score of %s", match)
                                .containsExactly(pressed.get(match));
                        return match;
                    })
                    .list();

            var standings = call("club1", get(events("/standings"))).expect(200).body();
            List<Map<String, Object>> rows = JsonPath.read(standings, "$");
            assertThat(rows).hasSize(countOf("select count(*) from participant where event_id = '" + event + "'"));
            for (var row : rows) {
                var person = (String) row.get("participantId");
                assertThat(row.get("matches")).as("matches of %s", person).isEqualTo(countOf(FOUGHT.formatted(person)));
                if (grappling) {
                    assertThat(row.get("wins")).as("wins of %s", person).isEqualTo(countOf(WON.formatted(person)));
                }
            }

            // The downloads tell the same: one line per person and per match, with the same order and totals.
            var csv = lines(call("club1", get(events("/export/standings.csv")))
                    .expect(200)
                    .body());
            assertThat(csv).hasSize(rows.size() + 1);
            for (int i = 0; i < rows.size(); i++) {
                var row = rows.get(i);
                assertThat(csv.get(i + 1))
                        .as("line %d of standings.csv", i + 1)
                        .startsWith(row.get("position") + ";")
                        .contains(";" + row.get("firstName") + ";", ";" + row.get("total") + ";");
            }
            assertThat(lines(call("club1", get(events("/export/matches.csv")))
                            .expect(200)
                            .body()))
                    .hasSize(expectedMatches + 1);
            call("club1", get(events("/export/full"))).expect(200);
            call("club1", get(events("/export/package"))).expect(200);
        }

        // Nothing running for a minute while matches wait: say why, with every mat's board.
        private void checkNotStalled() throws Exception {
            idleTicks = running.isEmpty() ? idleTicks + 1 : 0;
            if (idleTicks > 6) {
                var boards = new StringBuilder();
                for (var mat : MATS) {
                    boards.append("mat ")
                            .append(mat)
                            .append(isDisabled(mat) ? " (disabled)" : "")
                            .append(": ")
                            .append(isDisabled(mat) ? "" : board(mat))
                            .append('\n');
                }
                throw new AssertionError("the day stalled at tick " + tick + ", " + seen + "\n" + boards
                        + String.join("\n", log.subList(Math.max(0, log.size() - 30), log.size())));
            }
        }

        private boolean dayOver() {
            return expectedMatches > 0
                    && laterGroups.isEmpty()
                    && running.isEmpty()
                    && countOf("select count(*) from fight_match where status <> 'FINISHED' and event_id = '" + event
                                    + "'")
                            == 0
                    && seen.containsKey("match reopened");
        }

        private boolean isDisabled(int mat) {
            return jdbc.sql("select disabled_at is not null from mat where id = ?")
                    .param(matId(mat))
                    .query(Boolean.class)
                    .single();
        }

        private String board(int mat) throws Exception {
            return call(referee(mat), get("/api/v1/mats/" + matId(mat) + "/board"))
                    .expect(200)
                    .body();
        }

        private Answer act(int mat, String match, String start) throws Exception {
            return call(
                    referee(mat),
                    post("/api/v1/matches/" + match + "/events")
                            .content(start + ",\"knownEvents\":" + knownEvents(UUID.fromString(match)) + "}"));
        }

        private String referee(int mat) {
            return mat == QR_MAT ? qrUser : "arbitro" + mat;
        }

        private void keepQrSession(String body) {
            qrRefresh = JsonPath.read(body, "$.refreshToken");
            tokens.put(qrUser, JsonPath.read(body, "$.accessToken"));
        }

        private String token(String username) throws Exception {
            if (username.equals(qrUser)) {
                // The QR phone renews its session, it never knows the password.
                if (!tokens.containsKey(qrUser)) {
                    keepQrSession(anonymous(post("/api/v1/auth/refresh").content("""
                                    {"refreshToken":"%s"}""".formatted(qrRefresh)))
                            .expect(200)
                            .body());
                }
                return tokens.get(qrUser);
            }
            return tokens.computeIfAbsent(
                    username, u -> auth.login(u, u, "127.0.0.1").accessToken());
        }

        private Answer call(String username, MockHttpServletRequestBuilder request) throws Exception {
            return send(request.header(HttpHeaders.AUTHORIZATION, "Bearer " + token(username)));
        }

        private Answer anonymous(MockHttpServletRequestBuilder request) throws Exception {
            return send(request);
        }

        private Answer send(MockHttpServletRequestBuilder request) throws Exception {
            var response = mvc.perform(request.contentType(MediaType.APPLICATION_JSON))
                    .andReturn()
                    .getResponse();
            response.setCharacterEncoding(StandardCharsets.UTF_8.name());
            return new Answer(response.getStatus(), response.getContentAsString(), log);
        }

        private void log(String line) {
            log.add("t" + tick + " " + line);
        }

        private String events(String path) {
            return "/api/v1/events/" + event + path;
        }

        private UUID matId(int number) {
            return jdbc.sql("select id from mat where number = ? and event_id = ?")
                    .params(number, event)
                    .query(UUID.class)
                    .single();
        }

        private UUID categoryId(String name) {
            return jdbc.sql("select id from event_category where name = ? and event_id = ?")
                    .params(name, event)
                    .query(UUID.class)
                    .single();
        }
    }

    private record Planned(UUID category, List<String> people) {}

    private record Running(String match, int endTick, boolean inReview) {}

    private record Answer(int status, String body, List<String> log) {

        Answer expectOk() {
            assertThat(status / 100)
                    .as("%s%n%s", body, log.subList(Math.max(0, log.size() - 30), log.size()))
                    .isEqualTo(2);
            return this;
        }

        Answer expect(int expected) {
            assertThat(status)
                    .as("%s%n%s", body, log.subList(Math.max(0, log.size() - 30), log.size()))
                    .isEqualTo(expected);
            return this;
        }
    }

    private static final String LAST_WITH_POINTS = "select id::text from fight_match where mat_id = ?"
            + " and status = 'FINISHED' and end_reason = 'TIME' and red_score + blue_score > 0 order by finished_at desc, id limit 1";

    // Alone, or as a member of a team.
    private static final String FOUGHT = """
            select count(*) from fight_match f where f.status = 'FINISHED'
              and ('%1$s' in (f.red_participant_id, f.blue_participant_id)
                or exists (select 1 from team_member tm where tm.participant_id = '%1$s'
                  and tm.team_id in (f.red_team_id, f.blue_team_id)))""";

    private static final String WON = """
            select count(*) from fight_match where status = 'FINISHED'
              and ((red_participant_id = '%1$s' and winner_side = 'RED')
                or (blue_participant_id = '%1$s' and winner_side = 'BLUE'))""";

    private static String side(int side) {
        return side == 0 ? "RED" : "BLUE";
    }

    private static String quoted(List<String> ids) {
        return ids.stream().map(id -> "\"" + id + "\"").collect(Collectors.joining(","));
    }

    private static List<String> lines(String text) {
        return text.lines().filter(l -> !l.isBlank()).toList();
    }

    private int countOf(String sql) {
        return jdbc.sql(sql).query(Integer.class).single();
    }
}
