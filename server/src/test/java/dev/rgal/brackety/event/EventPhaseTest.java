package dev.rgal.brackety.event;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.notifications.CapturingEmailSender;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.ResultActions;

/** F1-7: start, finish, reopen, read-only once finished and the close the day after. */
class EventPhaseTest extends EventApiTest {

    @Autowired
    ParticipantRepository participants;

    @Autowired
    PhaseAutoClose autoClose;

    @Autowired
    CapturingEmailSender emails;

    List<UUID> sevens;

    @BeforeEach
    void notStartedYet() {
        jdbc.sql("update event set started_at = null where id = ?")
                .param(eventId)
                .update();
        sevens = new ArrayList<>();
        for (int i = 0; i < 8; i++) {
            var participant = new Participant(eventId, clock.instant());
            participant.update("Alumno" + i, "Prueba", LocalDate.of(2020, 3, 1), 120, true);
            sevens.add(participants.save(participant).getId());
        }
        emails.reset();
    }

    @Test
    void noGroupsUntilTheClubStartsThePhase() throws Exception {
        createGroup(0, 1, 2, 3)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("PHASE_NOT_STARTED"));
        call(post(phase() + "/start"), "ayudante1").andExpect(status().isForbidden());

        call(post(phase() + "/start"), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.state").value("IN_PROGRESS"));
        call(post(phase() + "/start"), "club1").andExpect(status().isConflict());

        createGroup(0, 1, 2, 3).andExpect(status().isCreated());
        call(get(phase()), "arbitro1").andExpect(jsonPath("$.state").value("IN_PROGRESS"));
    }

    @Test
    void finishedIsReadOnlyForEveryoneUntilTheClubReopensWithAReason() throws Exception {
        call(post(phase() + "/start"), "club1").andExpect(status().isOk());
        createGroup(0, 1, 2, 3).andExpect(status().isCreated());
        var match = firstMatch();
        call(post("/api/v1/matches/" + match + "/events").content("{\"type\":\"START\",\"knownEvents\":0}"), "arbitro1")
                .andExpect(status().isOk());

        call(post(phase() + "/finish"), "club1")
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("MATCH_IN_PROGRESS"));
        call(
                        post("/api/v1/matches/" + match + "/events")
                                .content("{\"type\":\"CANCEL\",\"knownEvents\":1,\"reason\":\"prueba\"}"),
                        "arbitro1")
                .andExpect(status().isOk());

        // Six matches never played: the app asked first, they stay unplayed in the history.
        call(get(phase()), "club1").andExpect(jsonPath("$.pendingMatches").value(6));
        call(post(phase() + "/finish"), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.state").value("FINISHED"));
        assertThat(lastChange()).isEqualTo("FINISH 6");

        createGroup(4, 5, 6, 7)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("PHASE_FINISHED"));
        call(post("/api/v1/matches/" + match + "/events").content("{\"type\":\"START\",\"knownEvents\":0}"), "arbitro1")
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("PHASE_FINISHED"));
        call(
                        put("/api/v1/events/" + eventId + "/participants/" + sevens.get(7) + "/measures")
                                .content("{\"weightKg\":30}"),
                        "ayudante1")
                .andExpect(status().isConflict());

        call(post(phase() + "/reopen").content("{\"reason\":\" \"}"), "club1").andExpect(status().isBadRequest());
        call(post(phase() + "/reopen").content("{\"reason\":\"Falta un combate\"}"), "ayudante1")
                .andExpect(status().isForbidden());
        call(post(phase() + "/reopen").content("{\"reason\":\"Falta un combate\"}"), "club1")
                .andExpect(jsonPath("$.state").value("IN_PROGRESS"));
        createGroup(4, 5, 6, 7).andExpect(status().isCreated());
    }

    @Test
    void theDayAfterItFinishesByItselfOrTellsTheClubOnceWhatIsLeft() throws Exception {
        call(post(phase() + "/start"), "club1").andExpect(status().isOk());
        createGroup(0, 1, 2, 3).andExpect(status().isCreated());
        clock.set(Instant.parse("2027-03-10T23:10:00Z"));

        autoClose.run();
        autoClose.run();

        call(get(phase()), "club1").andExpect(jsonPath("$.state").value("IN_PROGRESS"));
        assertThat(emails.sentTo("club1"))
                .singleElement()
                .satisfies(e -> assertThat(e.text()).contains("quedan 6 combates sin jugar"));

        jdbc.sql("update fight_match set status = 'FINISHED' where event_id = ?")
                .param(eventId)
                .update();
        autoClose.run();

        call(get(phase()), "club1").andExpect(jsonPath("$.state").value("FINISHED"));
        assertThat(lastChange()).isEqualTo("AUTO_FINISH 0");
        assertThat(emails.sentTo("club1").getLast().subject()).contains("ha finalizado");
    }

    private ResultActions createGroup(int... positions) throws Exception {
        var ids = java.util.Arrays.stream(positions)
                .mapToObj(i -> "\"" + sevens.get(i) + "\"")
                .collect(Collectors.joining(","));
        var category = jdbc.sql("select id from event_category where name = '7-8'")
                .query(UUID.class)
                .single();
        return call(post("/api/v1/events/" + eventId + "/groups").content("""
                        {"categoryId":"%s","groups":[{"participantIds":[%s]}]}""".formatted(category, ids)), "ayudante1");
    }

    private UUID firstMatch() {
        return jdbc.sql("select id from fight_match where event_id = ? order by order_index limit 1")
                .param(eventId)
                .query(UUID.class)
                .single();
    }

    private String lastChange() {
        return jdbc.sql("select action || ' ' || unplayed_matches from event_phase_change where event_id = ?"
                        + " order by created_at desc, action limit 1")
                .param(eventId)
                .query(String.class)
                .single();
    }

    private String phase() {
        return "/api/v1/events/" + eventId + "/phase";
    }
}
