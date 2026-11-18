package dev.rgal.brackety.common;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;

import dev.rgal.brackety.local.EmbeddedPostgresConfig;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest(
        properties = {
            "brackety.version=0.7.0+9",
            "brackety.commit=abc1234",
            "brackety.superadmin.email=root@example.test",
            "brackety.legal.privacy-contact-email="
        })
@AutoConfigureMockMvc
@Import(EmbeddedPostgresConfig.class)
class StartupReportTest {

    @Autowired
    StartupReport report;

    @Autowired
    MockMvc mvc;

    @Test
    void theLogSaysTheVersionTheDatabaseAndWhatIsMissing() {
        var lines = report.lines();

        assertThat(lines.getFirst()).isEqualTo("Brackety 0.7.0+9 (abc1234) is ready (production)");
        assertThat(lines)
                .anyMatch(l -> l.contains("Database") && l.contains("PostgreSQL 18.") && l.contains("schema V2026"))
                .anyMatch(l -> l.contains("Email") && l.contains("only to this log"))
                .anyMatch(l -> l.contains("Privacy contact") && l.contains("MISSING"))
                .anyMatch(l -> l.contains("Superadmin") && l.contains("closed"));
        // Settings say on or off, never their values.
        assertThat(String.join("\n", lines)).doesNotContain("root@example.test");
    }

    @Test
    void infoTellsTheVersion() throws Exception {
        mvc.perform(get("/api/v1/info")).andExpect(jsonPath("$.version").value("0.7.0+9"));
    }
}
