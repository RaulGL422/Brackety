package dev.rgal.brackety.grouping;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.fail;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.event.EventApiTest;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * A whole F1 day through the real API, with chance instead of a script (fixed seeds, so a failure repeats): 3 mats,
 * individual groups sent to any mat at any time with wildcards fighting elsewhere, groups of teams of 2 and 3 with
 * wildcard teams going to the pool, referees who sometimes take another match than the recommended one or try a
 * locked one, matches ended early by a disqualification, cancelled matches, groups undone before they start, and
 * optionally a mat without a referee.
 *
 * <p>After every step: nobody in two matches, one match per mat, nobody starts before the least rest, a mat with
 * individual matches of its own never takes one from the pool, a locked match is refused, and the day never stalls.
 * At the end every match is played exactly once.
 */
class EventDaySimulationTest extends EventApiTest {

    private static final Duration TICK = Duration.ofSeconds(10);
    private static final int INDIVIDUAL_TICKS = 6;
    private static final int TEAM_TICKS = 18;
    private static final int MIN_REST_SECONDS = 30;
    private static final String KIDS = "7-8";
    private static final String TEENS = "15-16";

    @Autowired
    ParticipantRepository participants;

    private final Map<String, String> tokens = new HashMap<>();

    @ParameterizedTest
    @ValueSource(longs = {11, 22, 33, 44, 55})
    void aDayOnThreeMatsEndsWithEveryMatchPlayedOnceAndTheRulesKept(long seed) throws Exception {
        new Day(new Random(seed), Set.of(1, 2, 3)).run();
    }

    @ParameterizedTest
    @ValueSource(longs = {66, 77})
    void aMatWithoutRefereeHoldsNothingBack(long seed) throws Exception {
        // Mat 3 is set up but nobody referees it: no individual group goes there, the pool must not wait for it.
        jdbc.sql("update mat set referee_account_id = null where number = 3").update();
        new Day(new Random(seed), Set.of(1, 2)).run();
    }

    private record Running(String matchId, int endTick, boolean team) {}

    private record Plan(int tick, boolean teams) {}

    private final class Day {

        private final Random random;
        private final Set<Integer> refereed;
        private final List<UUID> kids;
        private final List<UUID> teens;
        private final Map<String, List<UUID>> teamMembers = new HashMap<>();
        private final Set<UUID> kidsGrouped = new HashSet<>();
        private final Set<String> teamsGrouped = new HashSet<>();
        private final Map<String, Running> running = new HashMap<>();
        private final List<Plan> plans = new ArrayList<>();
        private final List<String> log = new ArrayList<>();
        private int tick;
        private int expectedMatches;
        private int idleTicks;
        private final Map<String, Integer> seen = new HashMap<>();
        private final Set<Integer> poolMats = new HashSet<>();

        Day(Random random, Set<Integer> refereed) throws Exception {
            this.random = random;
            this.refereed = refereed;
            jdbc.sql("delete from mat where number > 3").update();
            jdbc.sql("update event set match_seconds = 60, team_match_seconds = 180, team_points_limit = 0,"
                            + " min_rest_seconds = ?, changeover_seconds = 0")
                    .param(MIN_REST_SECONDS)
                    .update();
            kids = people(28, 7);
            teens = people(30, 15);
            makeTeams();
            // Groups arrive through the morning: a few at the start, the rest while others fight.
            for (int i = 0; i < 6; i++) {
                plans.add(new Plan(i < 2 ? 0 : random.nextInt(120), false));
            }
            for (int i = 0; i < 3; i++) {
                plans.add(new Plan(i == 0 ? 0 : random.nextInt(150), true));
            }
        }

        void run() throws Exception {
            for (tick = 0; tick < 3000; tick++) {
                for (var plan : List.copyOf(plans)) {
                    if (plan.tick() <= tick) {
                        plans.remove(plan);
                        createGroup(plan.teams());
                    }
                }
                if (random.nextInt(100) < 2) {
                    undoAGroup();
                }
                for (var mat : List.copyOf(refereed)) {
                    step(mat);
                }
                checkFloor();
                if (plans.isEmpty() && pending() == 0 && running.isEmpty()) {
                    break;
                }
                checkNotStalled();
                clock.advance(TICK);
                if (tick % 30 == 0) {
                    tokens.clear();
                }
            }
            assertThat(plans).as("groups still to create").isEmpty();
            assertThat(countOf("select count(*) from fight_match where status <> 'FINISHED'"))
                    .as("matches not played: %s", log)
                    .isZero();
            assertThat(countOf("select count(*) from fight_match")).isEqualTo(expectedMatches);
            // Played once: one last START per match after its last CANCEL, and one FINISH.
            assertThat(countOf("select count(*) from (select match_id from match_event where type = 'FINISH'"
                            + " group by match_id having count(*) <> 1) x"))
                    .isZero();
            // The day really went through the hard cases, not only the easy path.
            assertThat(seen)
                    .as("what the day went through")
                    .containsKeys("pool start", "locked refused", "cancel", "other than recommended");
        }

        private void step(int mat) throws Exception {
            var current = running.get(matKey(mat));
            if (current != null) {
                // At least one cancel a day, then by chance.
                if (random.nextInt(100) < 2 || (!seen.containsKey("cancel") && tick > 20)) {
                    act(mat, current.matchId(), "CANCEL", null).expect(200);
                    log("cancel " + current.matchId() + " on " + mat);
                    seen.merge("cancel", 1, Integer::sum);
                    running.remove(matKey(mat));
                } else if (tick >= current.endTick()) {
                    act(mat, current.matchId(), "FINISH", null).expect(200);
                    running.remove(matKey(mat));
                } else if (random.nextInt(100) < 3) {
                    // A disqualification ends it at once.
                    act(mat, current.matchId(), "DISQUALIFICATION", "RED").expect(200);
                    running.put(matKey(mat), new Running(current.matchId(), tick, current.team()));
                }
                return;
            }
            var board = board(mat);
            String recommended = JsonPath.read(board, "$.recommendedMatchId");
            List<String> available = JsonPath.read(board, "$.matches[?(@.available == true)].id");
            List<String> locked = JsonPath.read(
                    board,
                    "$.matches[?(@.status == 'PENDING' && @.available == false && @.waitReason != 'REVIEW')].id");
            if (recommended != null) {
                assertThat(available).as("the recommended match is available").contains(recommended);
            }
            // No mat stays idle while it could take a team match (Raul: as few free mats as possible): one whose
            // people are not in a match offered to another idle mat (that one is theirs).
            List<String> poolReady = JsonPath.read(
                    board, "$.matches[?(@.pool == true && @.available == true && @.waitReason == null)].id");
            List<String> offeredElsewhere = JsonPath.read(board, "$.matches[?(@.waitReason == 'OTHER_MAT')].id");
            var promised = new HashSet<String>();
            offeredElsewhere.forEach(m -> promised.addAll(fighters(m)));
            var free = poolReady.stream()
                    .filter(m -> fighters(m).stream().noneMatch(promised::contains))
                    .toList();
            if (!free.isEmpty()) {
                assertThat(recommended)
                        .as("tick %d: idle mat %d with team matches ready %s: %s", tick, mat, free, board)
                        .isNotNull();
            }
            var roll = random.nextInt(100);
            if (roll < 10 && !locked.isEmpty()) {
                var match = locked.get(random.nextInt(locked.size()));
                var answer = act(mat, match, "START", null);
                assertThat(answer.status())
                        .as("a locked match (%s) must not start: %s", match, answer.body())
                        .isEqualTo(409);
                seen.merge("locked refused", 1, Integer::sum);
                return;
            }
            String match =
                    roll < 30 && !available.isEmpty() ? available.get(random.nextInt(available.size())) : recommended;
            if (match == null) {
                return;
            }
            if (!match.equals(recommended)) {
                seen.merge("other than recommended", 1, Integer::sum);
            }
            start(mat, match);
        }

        private void start(int mat, String match) throws Exception {
            var team = isTeamMatch(match);
            var pool = isInPool(match);
            if (pool) {
                assertThat(countOf("select count(*) from fight_match where status = 'PENDING' and review_reason is null"
                                + " and mat_id = (select id from mat where number = " + mat + ")"))
                        .as("mat %d has individual matches of its own and takes %s from the pool", mat, match)
                        .isZero();
            }
            var fighters = fighters(match);
            var lastFought = lastFinished(fighters);
            var answer = act(mat, match, "START", null);
            assertThat(answer.status())
                    .as("tick %d: mat %d starts available %s: %s", tick, mat, match, answer.body())
                    .isEqualTo(200);
            if (lastFought != null) {
                assertThat(Duration.between(lastFought, clock.instant()))
                        .as("rest before %s", match)
                        .isGreaterThanOrEqualTo(Duration.ofSeconds(MIN_REST_SECONDS));
            }
            log("start " + match + " on " + mat + (pool ? " from the pool" : ""));
            if (pool) {
                seen.merge("pool start", 1, Integer::sum);
                poolMats.add(mat);
            }
            running.put(matKey(mat), new Running(match, tick + (team ? TEAM_TICKS : INDIVIDUAL_TICKS), team));
        }

        // Nobody in two matches, one match per mat.
        private void checkFloor() {
            assertThat(countOf("""
                            select count(*) from (
                              select p from (
                                select red_participant_id p from fight_match where status = 'IN_PROGRESS'
                                union all select blue_participant_id from fight_match where status = 'IN_PROGRESS'
                                union all select tm.participant_id from fight_match f join team_member tm
                                  on tm.team_id in (f.red_team_id, f.blue_team_id) where f.status = 'IN_PROGRESS'
                              ) x where p is not null group by p having count(*) > 1) y"""))
                    .as("tick %d: someone fights twice at once: %s", tick, log)
                    .isZero();
            assertThat(countOf("select count(*) from (select mat_id from fight_match where status = 'IN_PROGRESS'"
                            + " group by mat_id having count(*) > 1) x"))
                    .as("two matches on one mat")
                    .isZero();
        }

        // Pending matches and nothing in progress for longer than the least rest: the day is stuck.
        private void checkNotStalled() throws Exception {
            if (!running.isEmpty() || pending() == 0) {
                idleTicks = 0;
                return;
            }
            idleTicks++;
            if (idleTicks * TICK.toSeconds() > MIN_REST_SECONDS + TICK.toSeconds()) {
                var boards = new StringBuilder();
                for (var mat : refereed) {
                    boards.append("\nmat ").append(mat).append(": ").append(board(mat));
                }
                fail("tick %d: %d matches pending and nothing starts.%s\n%s", tick, pending(), boards, log);
            }
        }

        private void createGroup(boolean ofTeams) throws Exception {
            var category = categoryId(ofTeams ? TEENS : KIDS);
            String body;
            String mat;
            if (ofTeams) {
                var free = new ArrayList<>(teamMembers.keySet());
                free.removeAll(teamsGrouped);
                Collections.shuffle(free, random);
                var real = free.subList(0, Math.min(free.size(), 1 + random.nextInt(4)));
                if (real.isEmpty()) {
                    return;
                }
                var taken = real.stream()
                        .flatMap(t -> teamMembers.get(t).stream())
                        .collect(Collectors.toCollection(HashSet::new));
                var wildcards = new ArrayList<List<UUID>>();
                for (int i = real.size(); i < 4; i++) {
                    // Any of the category, also people of teams fighting in other groups.
                    var options = new ArrayList<>(teens);
                    options.removeAll(taken);
                    Collections.shuffle(options, random);
                    var wildcard = List.copyOf(options.subList(0, 2 + random.nextInt(2)));
                    taken.addAll(wildcard);
                    wildcards.add(wildcard);
                }
                body = """
                        {"teamIds":[%s],"ghostTeams":[%s]}""".formatted(
                        quoted(real),
                        wildcards.stream().map(w -> "[" + quoted(ids(w)) + "]").collect(Collectors.joining(",")));
                teamsGrouped.addAll(real);
                mat = "null";
            } else {
                var free = new ArrayList<>(kids);
                free.removeAll(kidsGrouped);
                Collections.shuffle(free, random);
                var real = List.copyOf(free.subList(0, Math.min(free.size(), 2 + random.nextInt(3))));
                if (real.isEmpty()) {
                    return;
                }
                var options = new ArrayList<>(kids);
                options.removeAll(real);
                Collections.shuffle(options, random);
                var ghosts = options.subList(0, 4 - real.size());
                body = """
                        {"participantIds":[%s],"ghostIds":[%s]}""".formatted(quoted(ids(real)), quoted(ids(ghosts)));
                kidsGrouped.addAll(real);
                var numbers = new ArrayList<>(refereed);
                Collections.sort(numbers);
                mat = "\"" + matId(numbers.get(random.nextInt(numbers.size()))) + "\"";
            }
            var answer = call(
                    "ayudante1",
                    post("/api/v1/events/" + eventId + "/groups").content("""
                            {"categoryId":"%s","groups":[%s],"matId":%s}""".formatted(category, body, mat)));
            assertThat(answer.status()).as("create %s: %s", body, answer.body()).isEqualTo(201);
            expectedMatches += 6;
            log("group of " + (ofTeams ? "teams" : "kids") + " on " + mat);
        }

        // A helper takes back a group nobody has started.
        private void undoAGroup() throws Exception {
            var candidates = jdbc.sql("select g.id from fight_group g where not exists (select 1 from fight_match f"
                            + " where f.group_id = g.id and (f.status <> 'PENDING' or exists (select 1 from match_event e"
                            + " where e.match_id = f.id)))")
                    .query(UUID.class)
                    .list();
            if (candidates.isEmpty()) {
                return;
            }
            var group = candidates.get(random.nextInt(candidates.size()));
            var members = jdbc.sql(
                            "select coalesce(participant_id, team_id) from group_member where group_id = ? and not ghost")
                    .param(group)
                    .query(UUID.class)
                    .list();
            var answer = call("ayudante1", delete("/api/v1/events/" + eventId + "/groups/" + group));
            assertThat(answer.status())
                    .as("undo a group nobody started: %s", answer.body())
                    .isEqualTo(204);
            members.forEach(kidsGrouped::remove);
            members.forEach(m -> teamsGrouped.remove(m.toString()));
            expectedMatches -= 6;
            log("undo group " + group);
            seen.merge("undo", 1, Integer::sum);
        }

        private void makeTeams() throws Exception {
            var free = new ArrayList<>(teens);
            Collections.shuffle(free, random);
            var category = categoryId(TEENS);
            while (free.size() >= 3) {
                var size = 2 + random.nextInt(2);
                var members = List.copyOf(free.subList(0, size));
                free.removeAll(members);
                var answer = call(
                        "ayudante1",
                        post("/api/v1/events/" + eventId + "/categories/" + category + "/teams")
                                .content("""
                                        {"participantIds":[%s]}""".formatted(quoted(ids(members)))));
                assertThat(answer.status()).as("team: %s", answer.body()).isEqualTo(201);
                teamMembers.put(JsonPath.read(answer.body(), "$.id"), members);
            }
        }

        private Answer act(int mat, String match, String type, String side) throws Exception {
            var reason = Set.of("DISQUALIFICATION", "CANCEL").contains(type) ? "\"prueba\"" : "null";
            return call(
                    "arbitro" + mat,
                    post("/api/v1/matches/" + match + "/events").content("""
                            {"type":"%s","side":%s,"reason":%s,"knownEvents":%d}""".formatted(
                                    type,
                                    side == null ? "null" : "\"" + side + "\"",
                                    reason,
                                    knownEvents(UUID.fromString(match)))));
        }

        private String board(int mat) throws Exception {
            var answer = call("arbitro" + mat, get("/api/v1/mats/" + matId(mat) + "/board"));
            assertThat(answer.status()).isEqualTo(200);
            return answer.body();
        }

        private int pending() {
            return countOf("select count(*) from fight_match where status <> 'FINISHED'");
        }

        private boolean isTeamMatch(String match) {
            return countOf("select count(*) from fight_match where id = '" + match + "' and red_team_id is not null")
                    > 0;
        }

        private boolean isInPool(String match) {
            return countOf("select count(*) from fight_match where id = '" + match + "' and mat_id is null") > 0;
        }

        private Set<String> fighters(String match) {
            return new HashSet<>(jdbc.sql("""
                            select p from (
                              select red_participant_id p from fight_match where id = ?::uuid
                              union select blue_participant_id from fight_match where id = ?::uuid
                              union select tm.participant_id from fight_match f join team_member tm
                                on tm.team_id in (f.red_team_id, f.blue_team_id) where f.id = ?::uuid) x
                            where p is not null""")
                    .params(match, match, match)
                    .query(String.class)
                    .list());
        }

        // The last finish of any match with one of these people.
        private Instant lastFinished(Set<String> people) {
            if (people.isEmpty()) {
                return null;
            }
            var in = people.stream().map(p -> "'" + p + "'").collect(Collectors.joining(","));
            return jdbc.sql("""
                            select max(f.finished_at) from fight_match f
                            where f.finished_at is not null and (f.red_participant_id in (%1$s)
                              or f.blue_participant_id in (%1$s)
                              or exists (select 1 from team_member tm where tm.team_id in (f.red_team_id, f.blue_team_id)
                                and tm.participant_id in (%1$s)))""".formatted(in)).query(Instant.class).optional().orElse(null);
        }

        private void log(String line) {
            log.add("t" + tick + " " + line);
        }

        private List<UUID> people(int count, int age) {
            var ids = new ArrayList<UUID>();
            for (int i = 0; i < count; i++) {
                var participant = new Participant(eventId, clock.instant());
                participant.update(
                        "S" + age + "-" + i, "Prueba", LocalDate.of(2027, 3, 1).minusYears(age), 120, true);
                ids.add(participants.save(participant).getId());
            }
            return ids;
        }
    }

    private record Answer(int status, String body) {

        Answer expect(int expected) {
            assertThat(status).as(body).isEqualTo(expected);
            return this;
        }
    }

    private static String matKey(int mat) {
        return "mat" + mat;
    }

    private static List<String> ids(List<UUID> ids) {
        return ids.stream().map(UUID::toString).toList();
    }

    private static String quoted(List<String> ids) {
        return ids.stream().map(id -> "\"" + id + "\"").collect(Collectors.joining(","));
    }

    private int countOf(String sql) {
        return jdbc.sql(sql).query(Integer.class).single();
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

    // One login per account while the clock allows it: hashing the password on every call is slow.
    private Answer call(String username, MockHttpServletRequestBuilder request) throws Exception {
        var token = tokens.computeIfAbsent(
                username, u -> auth.login(u, u, "127.0.0.1").accessToken());
        MockHttpServletResponse response = mvc.perform(request.header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON))
                .andReturn()
                .getResponse();
        return new Answer(response.getStatus(), response.getContentAsString());
    }
}
