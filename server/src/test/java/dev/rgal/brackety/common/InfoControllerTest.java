package dev.rgal.brackety.common;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(InfoController.class)
@Import(InfoControllerTest.FixedClock.class)
class InfoControllerTest {

    @Autowired
    MockMvc mvc;

    @Test
    void reportsTheServerDayFromTheClock() throws Exception {
        mvc.perform(get("/api/v1/info"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("brackety"))
                .andExpect(jsonPath("$.today").value("2027-03-10"));
    }

    @TestConfiguration(proxyBeanMethods = false)
    static class FixedClock {

        @Bean
        Clock clock() {
            // 23:30 UTC is already the next day in Madrid: the server day follows the app time zone.
            return Clock.fixed(Instant.parse("2027-03-09T23:30:00Z"), ZoneId.of("Europe/Madrid"));
        }
    }
}
