package dev.rgal.brackety.scoreboard;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.hasItem;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.event.Discipline;
import dev.rgal.brackety.event.EventRepository;
import java.time.Instant;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

/** F1-4: the warning reasons come from the sport, the club may change them, and the referee picks from them. */
class WarningReasonsTest extends ScoreboardApiTest {

    @Autowired
    EventRepository events;

    String reasons() {
        return "/api/v1/events/" + eventId + "/warning-reasons";
    }

    @Test
    void theSportsListUntilTheClubWritesItsOwnWhichTheRefereeGets() throws Exception {
        call(get("/api/v1/events/" + eventId + "/settings"), "club1")
                .andExpect(jsonPath("$.warningReasons.own").doesNotExist())
                .andExpect(jsonPath("$.warningReasons.sport", hasItem("Ataque de pique")));
        var match = match(older, 0, 1);
        call(get(path(match)), "arbitro2").andExpect(jsonPath("$.warningReasons", hasItem("Exceso de potencia")));

        call(put(reasons()).content("{\"reasons\":[\" Agarre \",\"agarre\",\"\",\"Salida de zona\"]}"), "club1")
                .andExpect(status().isBadRequest());
        call(put(reasons()).content("{\"reasons\":[\" Agarre \",\"agarre\",\"Salida de zona\"]}"), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.own", contains("Agarre", "Salida de zona")));
        call(get(path(match)), "arbitro2")
                .andExpect(jsonPath("$.warningReasons", contains("Agarre", "Salida de zona")));

        call(put(reasons()).content("{\"reasons\":null}"), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.own").doesNotExist());
        call(get(path(match)), "arbitro2")
                .andExpect(jsonPath("$.warningReasons[0]")
                        .value(Discipline.TAMBO.warningReasons().getFirst()));
    }

    @Test
    void onlyTheClubChangesThemAndTheyAreKeptShort() throws Exception {
        call(put(reasons()).content("{\"reasons\":[\"Agarre\"]}"), "ayudante1").andExpect(status().isForbidden());
        call(put(reasons()).content("{\"reasons\":[\"" + "x".repeat(61) + "\"]}"), "club1")
                .andExpect(status().isBadRequest());
    }

    @Test
    void theNextPhaseAndTheHallPackageKeepTheEventsOwnList() throws Exception {
        call(put(reasons()).content("{\"reasons\":[\"Agarre\"]}"), "club1").andExpect(status().isOk());

        var next = events.findById(eventId)
                .orElseThrow()
                .nextPhase(2, Discipline.TAMBO, "Fase 2", LocalDate.of(2027, 4, 10), 10, Instant.now());
        assertThat(next.getOwnWarningReasons()).containsExactly("Agarre");

        call(get("/api/v1/events/" + eventId + "/export/package"), "club1")
                .andExpect(jsonPath("$.event.warningReasons", contains("Agarre")));
    }

    @Test
    void anyReasonIsStillAcceptedForOtro() throws Exception {
        var match = match(older, 0, 1);
        call(post(path(match) + "/events").content("{\"type\":\"START\",\"knownEvents\":0}"), "arbitro2")
                .andExpect(status().isOk());
        call(
                        post(path(match) + "/events")
                                .content(
                                        "{\"type\":\"WARNING\",\"side\":\"RED\",\"reason\":\"Escrito a mano\",\"knownEvents\":1}"),
                        "arbitro2")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.timeline[1].reason").value("Escrito a mano"));
    }
}
