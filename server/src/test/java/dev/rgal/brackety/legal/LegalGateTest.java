package dev.rgal.brackety.legal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.event.EventApiTest;
import org.junit.jupiter.api.Test;
import org.springframework.test.context.TestPropertySource;

// The legal gate (docs/modulos/legal-paginas.md): without a privacy contact no phase starts and no next phase is
// created, so nobody's data is put to work without a way to exercise their rights.
@TestPropertySource(properties = "brackety.legal.privacy-contact-email=")
class LegalGateTest extends EventApiTest {

    @Test
    void withoutAPrivacyContactNoPhaseStartsAndNoneIsCreated() throws Exception {
        jdbc.sql("update event set started_at = null where id = ?")
                .param(eventId)
                .update();
        var before = phases();

        call(post("/api/v1/events/" + eventId + "/phase/start"), "club1")
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("LEGAL_GATE"));
        call(post("/api/v1/events/" + eventId + "/league/phases").content("""
                        {"name":"Fase 2","date":"2027-01-24","discipline":"TAMBO","attendancePoints":0}"""), "club1")
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("LEGAL_GATE"));

        assertThat(jdbc.sql("select started_at is null from event where id = ?")
                        .param(eventId)
                        .query(Boolean.class)
                        .single())
                .isTrue();
        assertThat(phases()).isEqualTo(before);
        call(get("/api/v1/legal"), "club1")
                .andExpect(jsonPath("$.privacyContactConfigured").value(false));
    }

    // Who may not start the phase hears that, not about the gate.
    @Test
    void whoMayNotStartThePhaseIsToldSoFirst() throws Exception {
        jdbc.sql("update event set started_at = null where id = ?")
                .param(eventId)
                .update();

        call(post("/api/v1/events/" + eventId + "/phase/start"), "ayudante1")
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").doesNotExist());
    }

    private int phases() {
        return jdbc.sql("select count(*) from event").query(Integer.class).single();
    }
}
