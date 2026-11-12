package dev.rgal.brackety.event;

import static org.hamcrest.Matchers.everyItem;
import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

// The demo event: club1, ayudante1-2 and arbitro1-5, one referee per mat.
class StaffNamesTest extends EventApiTest {

    @Autowired
    ParticipantRepository participants;

    @Test
    void theClubNamesThePeopleBehindTheAccountsAndEveryoneSeesWhoDidWhat() throws Exception {
        name("arbitro1", "Juan Pérez").andExpect(status().isNoContent());
        name("ayudante1", "Ana López").andExpect(status().isNoContent());

        call(get(event() + "/settings"), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.referees[?(@.username == 'arbitro1')].personName")
                        .value("Juan Pérez"))
                .andExpect(jsonPath("$.staff[?(@.username == 'ayudante1')].personName")
                        .value("Ana López"))
                .andExpect(jsonPath("$.staff[?(@.username == 'ayudante1')].roles[0]")
                        .value("GROUPER"))
                .andExpect(jsonPath("$.staff[?(@.username == 'ayudante2' && @.personName != null)]")
                        .isEmpty())
                .andExpect(jsonPath("$.staff[*].username", everyItem(is(org.hamcrest.Matchers.not("club1")))));
        call(get(event() + "/mats"), "club1")
                .andExpect(jsonPath("$[0].referee").value("Juan Pérez (arbitro1)"))
                .andExpect(jsonPath("$[1].referee").value("arbitro2"));

        var kids = new ArrayList<UUID>();
        for (int i = 0; i < 4; i++) {
            var p = new Participant(eventId, clock.instant());
            p.update("Niño" + i, "Prueba", LocalDate.of(2018, 1, 15), 130, true);
            kids.add(participants.save(p).getId());
        }
        var category = jdbc.sql("select id from event_category where name = '9-10'")
                .query(UUID.class)
                .single();
        var mat = jdbc.sql("select id from mat where event_id = ? and number = 1")
                .param(eventId)
                .query(UUID.class)
                .single();
        call(
                        post(event() + "/groups").content("""
                                {"categoryId":"%s","groups":[{"participantIds":[%s]}],"matId":"%s"}""".formatted(
                                category,
                                kids.stream().map(id -> "\"" + id + "\"").collect(Collectors.joining(",")),
                                mat)),
                        "ayudante1")
                .andExpect(status().isCreated());

        call(get("/api/v1/mats/" + mat + "/board"), "arbitro1")
                .andExpect(jsonPath("$.groups[0].createdBy").value("Ana López (ayudante1)"));
        call(get(event() + "/categories/" + category + "/participants"), "ayudante2")
                .andExpect(jsonPath("$[0].groupCreatedBy").value("Ana López (ayudante1)"));

        // A blank name takes it away again.
        name("ayudante1", " ").andExpect(status().isNoContent());
        call(get("/api/v1/mats/" + mat + "/board"), "arbitro1")
                .andExpect(jsonPath("$.groups[0].createdBy").value("ayudante1"));
    }

    @Test
    void onlyTheClubNamesAndOnlyItsOwnStaff() throws Exception {
        call(put(event() + "/staff/" + accountId("arbitro1") + "/name").content("""
                                {"name":"Juan"}"""), "ayudante1")
                .andExpect(status().isForbidden());
        call(put(event() + "/staff/" + UUID.randomUUID() + "/name").content("""
                                {"name":"Juan"}"""), "club1")
                .andExpect(status().isNotFound());
        call(put(event() + "/staff/" + accountId("arbitro1") + "/name").content("""
                                {"name":"%s"}""".formatted("x".repeat(81))), "club1")
                .andExpect(status().isBadRequest());
    }

    private org.springframework.test.web.servlet.ResultActions name(String username, String name) throws Exception {
        return call(put(event() + "/staff/" + accountId(username) + "/name").content("""
                        {"name":"%s"}""".formatted(name)), "club1");
    }

    private String event() {
        return "/api/v1/events/" + eventId;
    }
}
