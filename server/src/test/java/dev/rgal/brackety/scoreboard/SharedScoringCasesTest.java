package dev.rgal.brackety.scoreboard;

import static org.assertj.core.api.Assertions.assertThat;

import dev.rgal.brackety.scoreboard.MatchState.Entry;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Stream;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.TestFactory;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/** The scoring cases shared with the app (spec/scoring/*.json): both MatchState must agree on every one. */
class SharedScoringCasesTest {

    private static final List<String> SPORTS = List.of("tambo", "grappling");
    private static final Instant T0 = Instant.parse("2027-03-10T09:00:00Z");
    private static final Map<String, MatchRules.Scoring> SCORINGS =
            Map.of("TAMBO", MatchRules.Scoring.TAMBO, "GRAPPLING", MatchRules.Scoring.GRAPPLING);

    // The app names each refusal; the server words it. Both must mean the same.
    private static final Map<String, String> REFUSALS = Map.ofEntries(
            Map.entry("The match is finished.", "finished"),
            Map.entry("The match is over.", "over"),
            Map.entry(MatchRefusals.NOT_STARTED, "notStarted"),
            Map.entry("The clock is already running.", "running"),
            Map.entry("The clock is not running.", "notRunning"),
            Map.entry("Nothing to undo.", "nothingToUndo"),
            Map.entry("The match is not over yet.", "notOver"),
            Map.entry("The match is not finished.", "notFinished"),
            Map.entry("No points to take back.", "noPoints"),
            Map.entry("Stop the clock first.", "clockRunning"),
            Map.entry("The clock cannot go further.", "clockLimit"),
            Map.entry("Not in this sport.", "notInThisSport"),
            Map.entry("This sport has no such value.", "invalidValue"),
            Map.entry("No extra time: the match is not tied at the end.", "noExtraTime"),
            Map.entry("Tied after every tiebreaker: play the extra time first.", "extraTimePending"));

    @TestFactory
    Stream<DynamicTest> everySharedCase() throws Exception {
        var cases = new ArrayList<DynamicTest>();
        for (var sport : SPORTS) {
            var file = Path.of("..", "spec", "scoring", sport + ".json");
            var root = JsonMapper.builder().build().readTree(Files.readString(file, StandardCharsets.UTF_8));
            var defaults = root.get("rules");
            for (var testCase : root.get("cases")) {
                cases.add(DynamicTest.dynamicTest(
                        sport + ": " + testCase.get("name").asString(), () -> check(defaults, testCase)));
            }
        }
        return cases.stream();
    }

    private static void check(JsonNode defaults, JsonNode testCase) {
        var rules = testCase.has("rules") ? testCase.get("rules") : defaults;
        var length = (rules.has("length") ? rules : defaults).get("length").asInt();
        var limit =
                (rules.has("pointsLimit") ? rules : defaults).get("pointsLimit").asInt();
        var entries = new ArrayList<Entry>();
        for (var entry : testCase.get("entries")) {
            entries.add(entry(entry));
        }
        var scoring = (rules.has("scoring") ? rules : defaults).path("scoring").asString("TAMBO");
        var match = MatchState.replay(
                new MatchRules(Duration.ofSeconds(length), limit, SCORINGS.get(scoring)), List.copyOf(entries));
        var now = at(testCase.get("at"));
        var expect = testCase.get("expect");

        for (var side : Side.values()) {
            var key = side.name().toLowerCase();
            if (expect.has(key)) {
                var corner = expect.get(key);
                var actual = match.corner(side);
                if (corner.has("points")) {
                    assertThat(actual.points())
                            .as(key + " points")
                            .isEqualTo(corner.get("points").asInt());
                }
                if (corner.has("warnings")) {
                    assertThat(actual.warnings())
                            .as(key + " warnings")
                            .isEqualTo(corner.get("warnings").asInt());
                }
                if (corner.has("oneHandWarnings")) {
                    assertThat(actual.oneHandWarnings())
                            .as(key + " one-hand warnings")
                            .isEqualTo(corner.get("oneHandWarnings").asInt());
                }
            }
        }
        if (expect.has("elapsed")) {
            assertThat(match.elapsedAt(now)).as("elapsed").isEqualTo(duration(expect.get("elapsed")));
        }
        if (expect.has("running")) {
            assertThat(match.isRunning(now))
                    .as("running")
                    .isEqualTo(expect.get("running").asBoolean());
        }
        if (expect.has("started")) {
            assertThat(match.isStarted())
                    .as("started")
                    .isEqualTo(expect.get("started").asBoolean());
        }
        if (expect.has("finished")) {
            assertThat(match.isFinished())
                    .as("finished")
                    .isEqualTo(expect.get("finished").asBoolean());
        }
        if (expect.has("endReason")) {
            assertThat(match.endReason(now).map(Enum::name).orElse(null))
                    .as("end reason")
                    .isEqualTo(text(expect.get("endReason")));
        }
        if (expect.has("winner")) {
            assertThat(match.winner(now).map(Enum::name).orElse(null))
                    .as("winner")
                    .isEqualTo(text(expect.get("winner")));
        }
        if (expect.has("needsExtraTime")) {
            assertThat(match.needsExtraTime(now))
                    .as("needs extra time")
                    .isEqualTo(expect.get("needsExtraTime").asBoolean());
        }
        if (expect.has("disqualified")) {
            assertThat(
                            match.disqualified() == null
                                    ? null
                                    : match.disqualified().name())
                    .as("disqualified")
                    .isEqualTo(text(expect.get("disqualified")));
        }
        if (expect.has("lastUndoable")) {
            var last = text(expect.get("lastUndoable"));
            assertThat(match.lastUndoable().map(Entry::id))
                    .as("last undoable")
                    .isEqualTo(last == null ? Optional.empty() : Optional.of(id(last)));
        }
        if (expect.has("autoPoint")) {
            for (var warning : expect.get("autoPoint").properties()) {
                assertThat(match.gaveAutoPoint(id(warning.getKey())))
                        .as("warning " + warning.getKey() + " gave a point")
                        .isEqualTo(warning.getValue().asBoolean());
            }
        }
        if (expect.has("refuse")) {
            for (var refusal : expect.get("refuse")) {
                var type = MatchEventType.valueOf(refusal.get("action").asString());
                var side =
                        refusal.has("side") ? Side.valueOf(refusal.get("side").asString()) : null;
                var deltaMs =
                        refusal.has("delta") ? duration(refusal.get("delta")).toMillis() : 0;
                var value = refusal.path("value").asInt(1);
                var actual = match.refuse(type, side, deltaMs, value, now).map(REFUSALS::get);
                assertThat(actual.orElse(null)).as("refuse " + refusal).isEqualTo(text(refusal.get("expect")));
            }
        }
    }

    private static Entry entry(JsonNode entry) {
        var type = MatchEventType.valueOf(entry.get("action").asString());
        var side = entry.has("side") ? Side.valueOf(entry.get("side").asString()) : null;
        var target = entry.has("target") ? id(entry.get("target").asString()) : null;
        var deltaMs = entry.has("delta") ? duration(entry.get("delta")).toMillis() : 0;
        var value = entry.path("value").asInt(1);
        return new Entry(id(entry.get("id").asString()), type, side, at(entry.get("at")), target, deltaMs, value);
    }

    private static UUID id(String name) {
        return UUID.nameUUIDFromBytes(name.getBytes(StandardCharsets.UTF_8));
    }

    private static Instant at(JsonNode seconds) {
        return T0.plus(duration(seconds));
    }

    private static Duration duration(JsonNode seconds) {
        return Duration.ofMillis(Math.round(seconds.asDouble() * 1000));
    }

    private static String text(JsonNode node) {
        return node.isNull() ? null : node.asString();
    }
}
