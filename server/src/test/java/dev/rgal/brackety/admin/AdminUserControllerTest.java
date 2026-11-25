package dev.rgal.brackety.admin;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.everyItem;
import static org.hamcrest.Matchers.hasItem;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.auth.AuthException;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;

class AdminUserControllerTest extends AdminApiTestBase {

    private static final String REASON = """
            {"reason":"Pedido por el club"}""";

    @Test
    void searchesByEmailAPageAtATime() throws Exception {
        admin(get("/api/v1/admin/users?q=ARBITRO&size=2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(5))
                .andExpect(jsonPath("$.items.length()").value(2))
                .andExpect(jsonPath("$.items[*].email", everyItem(containsString("arbitro"))))
                .andExpect(jsonPath("$.items[0].profiles", hasItem("HELPER")));
        // LIKE's wildcards are plain characters: nobody's email has a %.
        admin(get("/api/v1/admin/users?q=%25")).andExpect(jsonPath("$.total").value(0));
        admin(get("/api/v1/admin/users?size=101")).andExpect(status().isBadRequest());
    }

    @Test
    void theDetailSaysHowItSignsInAndWhatItHas() throws Exception {
        admin(get("/api/v1/admin/users/" + accountId("club1")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.email").value("club1"))
                .andExpect(jsonPath("$.user.profiles", hasItem("CLUB")))
                .andExpect(jsonPath("$.signInMethods", hasItem("PASSWORD")))
                .andExpect(jsonPath("$.ownedEvents").value(1))
                .andExpect(jsonPath("$.user.suspended").value(false));
        admin(get("/api/v1/admin/users/" + UUID.randomUUID())).andExpect(status().isNotFound());
    }

    @Test
    void aSuspendedAccountIsSignedOutAndCannotSignInUntilLifted() throws Exception {
        var referee = accountId("arbitro1");
        var before = auth.login("arbitro1", "arbitro1", "127.0.0.1").accessToken();

        admin(post("/api/v1/admin/users/" + referee + "/suspend").content(REASON))
                .andExpect(status().isNoContent());

        mvc.perform(get("/api/v1/me").header(HttpHeaders.AUTHORIZATION, "Bearer " + before))
                .andExpect(status().isUnauthorized());
        assertThatThrownBy(() -> auth.login("arbitro1", "arbitro1", "127.0.0.1"))
                .isInstanceOfSatisfying(
                        AuthException.class,
                        e -> assertThat(e.getBody().getProperties()).containsEntry("code", "ACCOUNT_SUSPENDED"));
        admin(get("/api/v1/admin/users/" + referee))
                .andExpect(jsonPath("$.user.suspended").value(true));

        admin(post("/api/v1/admin/users/" + referee + "/unsuspend").content(REASON))
                .andExpect(status().isNoContent());
        assertThat(auth.login("arbitro1", "arbitro1", "127.0.0.1").accessToken())
                .isNotBlank();
        assertThat(audit()).containsExactly("USER_SUSPENDED", "USER_UNSUSPENDED");
    }

    @Test
    void aDeletedAccountWaitsForThePurgeAndAnOwnerOfEventsIsRefused() throws Exception {
        admin(post("/api/v1/admin/users/" + accountId("ayudante2") + "/delete").content(REASON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.deletesOn").isNotEmpty());
        assertThat(jdbc.sql("select status from account where email = 'ayudante2'")
                        .query(String.class)
                        .single())
                .isEqualTo("DELETED");

        admin(post("/api/v1/admin/users/" + accountId("club1") + "/delete").content(REASON))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("OWNS_EVENTS"));
        assertThat(audit()).containsExactly("USER_DELETED");
    }

    @Test
    void everyActionNeedsAReasonAndTheSuperadmin() throws Exception {
        var referee = accountId("arbitro2");
        admin(post("/api/v1/admin/users/" + referee + "/suspend").content("{}")).andExpect(status().isBadRequest());
        call(post("/api/v1/admin/users/" + referee + "/suspend").content(REASON), "club1")
                .andExpect(status().isForbidden());
        admin(post("/api/v1/admin/users/" + UUID.randomUUID() + "/suspend").content(REASON))
                .andExpect(status().isNotFound());
        assertThat(audit()).isEmpty();
    }

    // Only an account the superadmin enables for support sees the Connection screen (Raul, 2026-11-25).
    @Test
    void supportIsEnabledAndDisabledWithAReasonAndTheAccountSeesIt() throws Exception {
        var club = accountId("club1");
        call(get("/api/v1/me"), "club1").andExpect(jsonPath("$.support").value(false));

        admin(post("/api/v1/admin/users/" + club + "/support").content("""
                        {"enabled":true,"reason":"Soporte del club en la F2"}""")).andExpect(status().isNoContent());

        call(get("/api/v1/me"), "club1").andExpect(jsonPath("$.support").value(true));
        admin(get("/api/v1/admin/users/" + club))
                .andExpect(jsonPath("$.user.support").value(true));
        admin(post("/api/v1/admin/users/" + club + "/support").content("""
                        {"enabled":false,"reason":"Fin del soporte"}""")).andExpect(status().isNoContent());
        call(get("/api/v1/me"), "club1").andExpect(jsonPath("$.support").value(false));
        assertThat(jdbc.sql("select reason from admin_audit where action = 'SUPPORT_CHANGED' order by at")
                        .query(String.class)
                        .list())
                .containsExactly("on: Soporte del club en la F2", "off: Fin del soporte");
        admin(post("/api/v1/admin/users/" + club + "/support").content("{\"enabled\":true}"))
                .andExpect(status().isBadRequest());
        call(post("/api/v1/admin/users/" + club + "/support").content("""
                        {"enabled":true,"reason":"Yo mismo"}"""), "club1")
                .andExpect(status().is4xxClientError());
        call(get("/api/v1/me"), "club1").andExpect(jsonPath("$.support").value(false));
    }

    private List<String> audit() {
        return jdbc.sql("select action from admin_audit where action like 'USER_%' order by at")
                .query(String.class)
                .list();
    }
}
