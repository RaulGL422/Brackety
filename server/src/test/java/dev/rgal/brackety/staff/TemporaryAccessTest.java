package dev.rgal.brackety.staff;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.event.EventApiTest;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/** Access by QR: a temporary account for one event, one device at a time, while the phase lasts. */
class TemporaryAccessTest extends EventApiTest {

    String accesses() {
        return "/api/v1/events/" + eventId + "/temporary-access";
    }

    String create(String body) throws Exception {
        return call(post(accesses()).content(body), "club1")
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
    }

    static String code(String response) {
        String link = JsonPath.read(response, "$.link");
        return link.substring(link.indexOf("code=") + 5);
    }

    ResultActions signIn(String code) throws Exception {
        return mvc.perform(post("/api/v1/auth/temporary")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"token\":\"%s\"}".formatted(code)));
    }

    String accessToken(String code) throws Exception {
        var body = signIn(code)
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }

    ResultActions as(String token, MockHttpServletRequestBuilder request) throws Exception {
        return mvc.perform(
                request.header(HttpHeaders.AUTHORIZATION, "Bearer " + token).contentType(MediaType.APPLICATION_JSON));
    }

    @Test
    void aRefereeWithoutAccountScansTheQrAndRefereesTheirMatOnly() throws Exception {
        var created = create("{\"name\":\" Juan Pérez \",\"role\":\"REFEREE\",\"mat\":2}");
        assertThat(JsonPath.<String>read(created, "$.link")).contains("/qr?code=");
        assertThat(JsonPath.<Integer>read(created, "$.mat")).isEqualTo(2);
        assertThat(JsonPath.<Boolean>read(created, "$.waiting")).isTrue();

        var code = code(created);
        var token = accessToken(code);
        // The code works once.
        signIn(code).andExpect(status().is4xxClientError());

        as(token, get("/api/v1/events")).andExpect(jsonPath("$[0].id").value(eventId.toString()));
        as(token, get("/api/v1/me")).andExpect(jsonPath("$.temporary").value(true));
        // Nothing outside its event: no events of its own, no account changes.
        as(token, post("/api/v1/events").content("""
                        {"name":"Mío","date":"2027-05-08","discipline":"TAMBO","mats":1}""")).andExpect(status().isForbidden());
        as(token, patch("/api/v1/me").content("{\"locale\":\"en\"}")).andExpect(status().isForbidden());
        // Nor the club's settings.
        as(token, get(accesses())).andExpect(status().isForbidden());

        // The club sees it came in, with the name it typed.
        call(get(accesses()), "club1")
                .andExpect(jsonPath("$[0].name").value("Juan Pérez"))
                .andExpect(jsonPath("$[0].waiting").value(false))
                .andExpect(jsonPath("$[0].signedInAt").isNotEmpty());
        call(get("/api/v1/events/" + eventId + "/settings"), "club1")
                .andExpect(jsonPath("$.mats[1].refereeId").value(JsonPath.<String>read(created, "$.accountId")));
    }

    @Test
    void renewingPutsTheOldDeviceOutAndFinishingThePhaseEndsIt() throws Exception {
        var created = create("{\"name\":\"Lucía\",\"role\":\"GROUPER\"}");
        var id = JsonPath.<String>read(created, "$.id");
        var first = accessToken(code(created));

        clock.advance(Duration.ofMinutes(1));
        var renewed = call(post(accesses() + "/" + id + "/renew"), "club1")
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        as(first, get("/api/v1/events")).andExpect(status().isUnauthorized());
        var second = accessToken(code(renewed));
        as(second, get("/api/v1/events")).andExpect(status().isOk());

        clock.advance(Duration.ofMinutes(1));
        call(post("/api/v1/events/" + eventId + "/phase/finish"), "club1").andExpect(status().isOk());
        as(second, get("/api/v1/events")).andExpect(status().isUnauthorized());
        call(get(accesses()), "club1").andExpect(jsonPath("$[0].ended").value(true));
        // Once the phase is over, no new code either.
        call(post(accesses() + "/" + id + "/renew"), "club1").andExpect(status().isConflict());
    }

    @Test
    void onlyTheClubCreatesThem() throws Exception {
        call(post(accesses()).content("{\"name\":\"X\",\"role\":\"REFEREE\"}"), "ayudante1")
                .andExpect(status().is4xxClientError());
        call(post(accesses()).content("{\"name\":\"X\",\"role\":\"GROUPER\",\"mat\":1}"), "club1")
                .andExpect(status().isBadRequest());
        signIn("not-a-code").andExpect(status().is4xxClientError());
    }
}
