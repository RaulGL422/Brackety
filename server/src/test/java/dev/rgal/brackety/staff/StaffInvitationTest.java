package dev.rgal.brackety.staff;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.event.EventApiTest;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.ResultActions;

/** F1-5: the club invites helpers and referees by email; they accept with their own account. */
class StaffInvitationTest extends EventApiTest {

    static final String ANA = "ana.arbitra@example.test";

    String invitations() {
        return "/api/v1/events/" + eventId + "/invitations";
    }

    ResultActions invite(String email, String role, String as) throws Exception {
        return call(post(invitations()).content("{\"email\":\"%s\",\"role\":\"%s\"}".formatted(email, role)), as);
    }

    ResultActions token(String action, String token, String as) throws Exception {
        return call(post("/api/v1/invitations/" + action).content("{\"token\":\"%s\"}".formatted(token)), as, PASSWORD);
    }

    String account(String email, boolean verified) {
        auth.register(registration(email));
        if (verified) {
            jdbc.sql("update account set email_verified = true where email = ?")
                    .param(email)
                    .update();
        }
        return email;
    }

    @Test
    void anInvitedRefereeAcceptsWithTheirOwnAccountAndGetsAMat() throws Exception {
        invite("Ana.Arbitra@Example.test", "REFEREE", "club1")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.email").value(ANA))
                .andExpect(jsonPath("$.expired").value(false));
        var email = emails.sentTo(ANA).getLast();
        assertThat(email.link()).contains("/invitation?token=");
        assertThat(email.text()).contains("árbitro");
        call(get(invitations()), "club1").andExpect(jsonPath("$", hasSize(1)));

        // Sent again only after a minute; the first link stops working.
        invite(ANA, "REFEREE", "club1")
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("INVITATION_TOO_SOON"));
        clock.advance(Duration.ofMinutes(2));
        invite(ANA, "REFEREE", "club1").andExpect(status().isCreated());
        var old = tokenIn(email);
        var link = tokenIn(emails.sentTo(ANA).getLast());
        call(get(invitations()), "club1").andExpect(jsonPath("$", hasSize(1)));

        account(ANA, true);
        token("view", old, ANA).andExpect(status().isNotFound());
        token("view", link, ANA)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role").value("REFEREE"))
                .andExpect(jsonPath("$.forYou").value(true));
        token("accept", link, ANA)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.eventId").value(eventId.toString()));
        token("accept", link, ANA).andExpect(status().isNotFound());

        call(get(invitations()), "club1").andExpect(jsonPath("$", hasSize(0)));
        call(get("/api/v1/events/" + eventId + "/settings"), "club1")
                .andExpect(jsonPath("$.referees[*].username", hasItem(ANA)));
        call(get("/api/v1/events"), ANA, PASSWORD).andExpect(jsonPath("$[0].id").value(eventId.toString()));
        invite(ANA, "REFEREE", "club1")
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ALREADY_STAFF"));
    }

    @Test
    void onlyTheInvitedEmailAcceptsAndOnlyVerified() throws Exception {
        invite(ANA, "GROUPER", "club1").andExpect(status().isCreated());
        var link = tokenIn(emails.sentTo(ANA).getLast());

        var other = account("otra@example.test", true);
        token("view", link, other).andExpect(jsonPath("$.forYou").value(false));
        token("accept", link, other)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("INVITATION_OTHER_EMAIL"));

        account(ANA, false);
        token("accept", link, ANA).andExpect(status().isForbidden());
    }

    @Test
    void anOldLinkExpiresAndTheClubCancelsOne() throws Exception {
        invite(ANA, "GROUPER", "club1").andExpect(status().isCreated());
        var link = tokenIn(emails.sentTo(ANA).getLast());
        account(ANA, true);

        clock.advance(Duration.ofDays(15));
        token("view", link, ANA).andExpect(status().isNotFound());
        call(get(invitations()), "club1").andExpect(jsonPath("$[0].expired").value(true));

        var id = com.jayway.jsonpath.JsonPath.<String>read(
                call(get(invitations()), "club1").andReturn().getResponse().getContentAsString(), "$[0].id");
        call(delete(invitations() + "/" + id), "club1").andExpect(status().isNoContent());
        call(get(invitations()), "club1").andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    void onlyTheClubInvitesAndRemovesAndARefereeLeavesTheirMatFirst() throws Exception {
        invite(ANA, "REFEREE", "ayudante1").andExpect(status().isForbidden());
        call(
                        post(invitations()).content("{\"email\":\"%s\",\"role\":\"REFEREE\"}".formatted(ANA)),
                        outsider(),
                        PASSWORD)
                .andExpect(status().isNotFound());
        invite(ANA, "CLUB", "club1").andExpect(status().isBadRequest());
        invite("not-an-email", "REFEREE", "club1").andExpect(status().isBadRequest());

        var staff = "/api/v1/events/" + eventId + "/staff/";
        call(delete(staff + accountId("arbitro1") + "?role=REFEREE"), "club1")
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("REFEREE_ON_MAT"));
        call(delete(staff + accountId("club1") + "?role=CLUB"), "club1").andExpect(status().isBadRequest());
        call(delete(staff + accountId("ayudante1") + "?role=GROUPER"), "club1").andExpect(status().isNoContent());
        call(get("/api/v1/events/" + eventId + "/settings"), "club1")
                .andExpect(jsonPath("$.staff[*].username", not(hasItem("ayudante1"))));
        call(get("/api/v1/events"), "ayudante1").andExpect(jsonPath("$", hasSize(0)));
    }
}
