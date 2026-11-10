package dev.rgal.brackety.admin;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.auth.admin.CloudflareAccess;
import java.util.Map;
import org.junit.jupiter.api.Test;

class AdminMetricsControllerTest extends AdminApiTestBase {

    @Test
    void countsWhatIsThereNow() throws Exception {
        admin(get("/api/v1/admin/metrics"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.events.total").value(1))
                .andExpect(jsonPath("$.events.entries").value(8))
                .andExpect(jsonPath("$.activity.groupsCreated24h").value(2))
                .andExpect(jsonPath("$.activity.matchesInProgress").value(0))
                .andExpect(
                        jsonPath("$.users.active").value(rows("select count(*) from account where status = 'ACTIVE'")))
                .andExpect(jsonPath("$.server.serverErrors").isNumber());
    }

    @Test
    void everyProfileHasItsTileEvenWithNobody() throws Exception {
        Map<String, Integer> byProfile = JsonPath.read(metrics(), "$.users.byProfile");

        assertThat(byProfile).containsOnlyKeys("CLUB", "EXTERNAL_ENTITY", "HELPER", "STUDENT", "EXTERNAL");
        assertThat(byProfile.get("HELPER")).isEqualTo(rows("select count(*) from profile where type = 'HELPER'"));
    }

    @Test
    void theScoreboardShowsInTheActivity() throws Exception {
        var match = match(young, 0, 1);

        referee(match, "START", null, 0);
        referee(match, "POINT", "RED", 1);
        var body = metrics();

        assertThat((int) JsonPath.read(body, "$.activity.matchesInProgress")).isOne();
        // The automatic stops are not the referee's: only START and POINT count.
        assertThat((int) JsonPath.read(body, "$.activity.scoreboardActions24h")).isEqualTo(2);
    }

    @Test
    void onlyTheSuperadminSeesThem() throws Exception {
        // A club's own token, even through Access, is not the superadmin's; without Access, not even that.
        call(get("/api/v1/admin/metrics").header(CloudflareAccess.HEADER, cloudflare.assertion()), "club1")
                .andExpect(status().isUnauthorized());
        call(get("/api/v1/admin/metrics"), "club1").andExpect(status().isForbidden());
    }

    private String metrics() throws Exception {
        return admin(get("/api/v1/admin/metrics"))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
    }
}
