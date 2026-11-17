package dev.rgal.brackety.devdata;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasItems;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.auth.admin.CloudflareAccess;
import dev.rgal.brackety.auth.admin.FakeCloudflareAccess;
import dev.rgal.brackety.common.MutableClock;
import dev.rgal.brackety.event.EventApiTest;
import dev.rgal.debug.DebugClock;
import dev.rgal.debug.DebugConfig;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/** The debug server's API (docs/modulos/entornos.md), on the demo event. */
@Import({DebugConfig.class, DebugControllerTest.TestClock.class})
class DebugControllerTest extends EventApiTest {

    /** Over the tests' clock, which stays the primary one. */
    @TestConfiguration(proxyBeanMethods = false)
    static class TestClock {

        @Bean
        DebugClock debugClock(MutableClock clock) {
            return new DebugClock(clock);
        }
    }

    @Autowired
    FakeCloudflareAccess cloudflare;

    @Autowired
    DebugClock debugClock;

    String token;

    @BeforeEach
    void signIn() throws Exception {
        debugClock.moveTo(null);
        var body = mvc.perform(post("/api/v1/admin/auth/login")
                        .header(CloudflareAccess.HEADER, cloudflare.assertion())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","password":"%s"}""".formatted(SUPERADMIN_EMAIL, PASSWORD)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        token = JsonPath.read(body, "$.accessToken");
    }

    @Test
    void theSuperadminLoadsAScenarioOnASimulatedDayAndWipesTheRest() throws Exception {
        admin(get("/api/v1/admin/dev/scenarios"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].name", hasItems("empty", "yoseikan-f1")));
        var before = rows("account");

        admin(post("/api/v1/admin/dev/scenarios/empty/load").content("{\"confirm\":\"emptyy\"}"))
                .andExpect(status().isBadRequest());
        admin(post("/api/v1/admin/dev/scenarios/nope/load").content("{\"confirm\":\"nope\"}"))
                .andExpect(status().isNotFound());
        admin(post("/api/v1/admin/dev/scenarios/empty/load")
                        .content("{\"confirm\":\"empty\",\"today\":\"2027-01-24\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.scenario").value("empty"))
                .andExpect(jsonPath("$.today").value("2027-01-24"))
                .andExpect(jsonPath("$.simulated").value(true));

        // Everything from before is gone; the load itself is audited after the wipe.
        assertThat(before).isPositive();
        assertThat(rows("account")).isZero();
        assertThat(rows("event")).isZero();
        assertThat(jdbc.sql("select target from admin_audit where action = 'DEBUG_CHANGE'")
                        .query(String.class)
                        .list())
                .containsExactly("empty");

        admin(put("/api/v1/admin/dev/clock").content("{\"today\":null}"))
                .andExpect(jsonPath("$.simulated").value(false))
                .andExpect(jsonPath("$.today").value("2027-03-10"));
    }

    @Test
    void onlyTheSuperadmin() throws Exception {
        call(get("/api/v1/admin/dev/scenarios"), "club1").andExpect(status().is4xxClientError());
        mvc.perform(get("/api/v1/admin/dev")).andExpect(status().is4xxClientError());
    }

    private int rows(String table) {
        return jdbc.sql("select count(*) from " + table).query(Integer.class).single();
    }

    private ResultActions admin(MockHttpServletRequestBuilder request) throws Exception {
        return mvc.perform(request.contentType(MediaType.APPLICATION_JSON)
                .header(CloudflareAccess.HEADER, cloudflare.assertion())
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token));
    }
}
