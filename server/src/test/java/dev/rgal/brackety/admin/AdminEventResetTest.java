package dev.rgal.brackety.admin;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.eventpackage.EventPackageReset;
import dev.rgal.brackety.eventpackage.EventPackageService;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.beans.factory.annotation.Autowired;
import tools.jackson.databind.json.JsonMapper;

/** The superadmin's "start the event again" (EventPackageReset): back to what the package holds. */
class AdminEventResetTest extends AdminApiTestBase {

    @Autowired
    EventPackageService packages;

    @Autowired
    JsonMapper json;

    @Test
    void aServerWithoutAPackageHasNothingToResetTo() throws Exception {
        admin(get("/api/v1/admin/event-reset"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.packageName").doesNotExist());
        admin(post("/api/v1/admin/event-reset").content("{\"reason\":\"prueba\"}"))
                .andExpect(status().isNotFound());
        call(get("/api/v1/admin/event-reset"), "club1").andExpect(status().is4xxClientError());
        assertThat(rows("select count(*) from fight_group")).isEqualTo(2);
    }

    @Test
    void whatWasDoneAfterThePackageGoesAndTheAuditStays(@TempDir Path dir) throws Exception {
        var file = Files.write(
                dir.resolve("f1.brackety"), json.writeValueAsBytes(packages.export(eventId, accountId("club1"))));
        // After the package: a match starts and a new group is made.
        referee(match(young, 0, 1), "START", null, 0);
        group("9-10", participants(10, "Otro"));
        var audit = rows("select count(*) from admin_audit");
        assertThat(audit).isPositive();

        new EventPackageReset(packages, jdbc, file.toString()).reset();

        // The package's two groups, untouched.
        assertThat(rows("select count(*) from fight_group")).isEqualTo(2);
        assertThat(rows("select count(*) from fight_match")).isEqualTo(12);
        assertThat(rows("select count(*) from match_event")).isZero();
        assertThat(rows("select count(*) from participant")).isEqualTo(8);
        assertThat(rows("select count(*) from event")).isOne();
        assertThat(rows("select count(*) from admin_audit")).isEqualTo(audit);
    }
}
