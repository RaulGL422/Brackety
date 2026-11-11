package dev.rgal.brackety.eventpackage;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.event.EventApiTest;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

class EventPackageControllerTest extends EventApiTest {

    @Test
    void theClubDownloadsTheEventAsAFile() throws Exception {
        call(get(url()), "club1")
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(header().string(
                                "Content-Disposition",
                                "attachment; filename=\"liga-yoseikan-2027-fase-1-tambo-2027-03-10.brackety\""))
                .andExpect(jsonPath("$.schemaVersion").value(EventPackage.SCHEMA_VERSION))
                .andExpect(jsonPath("$.event.date").value("2027-03-10"))
                .andExpect(jsonPath("$.owner.username").value("club1"))
                .andExpect(jsonPath("$.staff", hasSize(8)))
                .andExpect(jsonPath("$.mats[0].refereeUsername").value("arbitro1"))
                .andExpect(jsonPath("$.staff[0].id").doesNotExist());
    }

    @Test
    void onlyTheClubStaffOfTheEvent() throws Exception {
        call(get(url()), "ayudante1").andExpect(status().isForbidden());
        call(get(url()), "arbitro1").andExpect(status().isForbidden());
        call(get(url()), outsider(), PASSWORD).andExpect(status().isNotFound());
        mvc.perform(get(url())).andExpect(status().isUnauthorized());
    }

    @Test
    void slugKeepsLettersAndDigits() {
        assertThat(EventPackageService.slug("Liga Yoseikan · Fase 1 · Tambo")).isEqualTo("liga-yoseikan-fase-1-tambo");
        assertThat(EventPackageService.slug("Campeonato Ñandú")).isEqualTo("campeonato-nandu");
        assertThat(EventPackageService.slug("···")).isEqualTo("evento");
    }

    private String url() {
        return "/api/v1/events/" + eventId + "/export/package";
    }
}
