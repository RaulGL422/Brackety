package dev.rgal.brackety.scoreboard;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.common.QueryCounter;
import dev.rgal.brackety.participant.Participant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;

/**
 * SQL statements per read that devices repeat all day (every live "changed" makes each screen read again). A budget
 * only goes down: if a change needs more, read the statements the failure prints first. None may grow with the
 * event: a statement per group, category or staff member is an N+1.
 */
@Import(QueryCounter.class)
class QueryBudgetTest extends ScoreboardApiTest {

    private static final Map<String, Integer> BUDGET = Map.ofEntries(
            Map.entry("board", 15),
            Map.entry("match", 17),
            Map.entry("mat-groups", 11),
            Map.entry("mats", 14),
            Map.entry("standings", 14),
            Map.entry("categories", 13),
            Map.entry("participants", 7),
            Map.entry("events", 9),
            Map.entry("settings", 12),
            Map.entry("phase", 5),
            Map.entry("me", 5));

    @Test
    void theReadsDevicesRepeatStayWithinBudgetAndDoNotGrowWithTheEvent() throws Exception {
        var before = measure();
        before.forEach((read, statements) -> assertThat(statements.size())
                .as("%s:%n%s", read, String.join("\n", statements))
                .isLessThanOrEqualTo(BUDGET.get(read)));

        for (int i = 0; i < 4; i++) {
            addGroup(i % 2 == 0 ? "4-6" : "9-10", i % 2 == 0 ? 6 : 9);
        }

        measure()
                .forEach((read, statements) -> assertThat(statements.size())
                        .as("%s with more groups:%n%s", read, String.join("\n", statements))
                        .isEqualTo(before.get(read).size()));
    }

    private Map<String, List<String>> measure() throws Exception {
        var match = match(young, 0, 1);
        var club = token("club1");
        var referee = token("arbitro1");
        var event = "/api/v1/events/" + eventId;
        var result = new LinkedHashMap<String, List<String>>();
        result.put("board", statements("/api/v1/mats/" + matOf(match) + "/board", referee));
        result.put("match", statements(path(match), referee));
        result.put("mat-groups", statements(event + "/mat-groups", club));
        result.put("mats", statements(event + "/mats", club));
        result.put("standings", statements(event + "/standings", club));
        result.put("categories", statements(event + "/categories", club));
        result.put("participants", statements(event + "/participants", club));
        result.put("events", statements("/api/v1/events", club));
        result.put("settings", statements(event + "/settings", club));
        result.put("phase", statements(event + "/phase", club));
        result.put("me", statements("/api/v1/me", club));
        return result;
    }

    private List<String> statements(String path, String token) throws Exception {
        QueryCounter.reset();
        mvc.perform(get(path).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk());
        return QueryCounter.statements();
    }

    private String token(String username) {
        return auth.login(username, username, "127.0.0.1").accessToken();
    }

    private void addGroup(String category, int age) throws Exception {
        var ids = new ArrayList<UUID>();
        for (int i = 0; i < 4; i++) {
            var participant = new Participant(eventId, clock.instant());
            participant.update("Extra" + i, "Prueba", LocalDate.of(2027, 3, 1).minusYears(age), 110, true);
            ids.add(participants.save(participant).getId());
        }
        var categoryId = jdbc.sql("select id from event_category where name = ?")
                .param(category)
                .query(UUID.class)
                .single();
        var list = ids.stream().map(id -> "\"" + id + "\"").collect(Collectors.joining(","));
        call(post("/api/v1/events/" + eventId + "/groups").content("""
                                {"categoryId":"%s","groups":[{"participantIds":[%s]}]}""".formatted(categoryId, list)), "ayudante1")
                .andExpect(status().isCreated());
    }
}
