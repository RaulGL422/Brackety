package dev.rgal.brackety.admin;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;

// Hall mode (ADMIN_LOCAL_ONLY): no Cloudflare Access on the laptop; only the laptop itself gets in.
@TestPropertySource(properties = "brackety.admin.local-only=true")
class AdminLocalOnlyTest extends AdminApiTestBase {

    private static final String REASON = """
            {"reason":"Error del árbitro"}""";

    @Test
    void theLaptopResetsAMatchAndDissolvesAGroupWithoutAccess() throws Exception {
        var match = match(young, 0, 1);
        referee(match, "START", null, 0);
        referee(match, "POINT", "RED", 1);

        local(post("/api/v1/admin/matches/" + match + "/reset")).andExpect(status().isNoContent());
        assertThat(rows("select count(*) from match_event where match_id = ?", match)).isZero();
        referee(match, "START", null, 0);

        var group = jdbc.sql("select group_id from fight_match where id = ?")
                .param(match)
                .query(java.util.UUID.class)
                .single();
        local(post("/api/v1/admin/groups/" + group + "/dissolve")).andExpect(status().isNoContent());
        assertThat(rows("select count(*) from fight_match where group_id = ?", group)).isZero();
        group("4-6", young);
    }

    @Test
    void aPhoneOnTheHallNetworkIsRefused() throws Exception {
        mvc.perform(post("/api/v1/admin/auth/login")
                        .with(r -> {
                            r.setRemoteAddr("192.168.137.23");
                            return r;
                        })
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","password":"%s"}""".formatted(SUPERADMIN_EMAIL, PASSWORD)))
                .andExpect(status().isForbidden());
    }

    private org.springframework.test.web.servlet.ResultActions local(
            org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder request) throws Exception {
        return mvc.perform(request.contentType(MediaType.APPLICATION_JSON)
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .content(REASON));
    }
}
