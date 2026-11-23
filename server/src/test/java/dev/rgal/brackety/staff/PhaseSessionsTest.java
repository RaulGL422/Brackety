package dev.rgal.brackety.staff;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
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

/**
 * Server battery, «Sesiones» (docs/04-testing.md, GR-8): with the clock simulated, a referee's session (a normal
 * account and a temporary one by QR) lasts the whole phase through lost network and late retries; it ends only when
 * the phase does (temporary), «Quitar acceso» ({@link TemporaryAccessTest}) or a real theft (SessionServiceTest).
 */
class PhaseSessionsTest extends EventApiTest {

    /** A device: the refresh token it holds and the access token it uses. */
    private final class Device {
        String refresh;
        String access;

        Device(String body) {
            take(body);
        }

        void take(String body) {
            refresh = JsonPath.read(body, "$.refreshToken");
            access = JsonPath.read(body, "$.accessToken");
        }

        /** Renews; the answer arrives. */
        void renew() throws Exception {
            take(refresh(refresh)
                    .andExpect(status().isOk())
                    .andReturn()
                    .getResponse()
                    .getContentAsString());
        }

        /** Renews, but the answer never arrives: the device keeps its old tokens. */
        void renewLosingTheAnswer() throws Exception {
            refresh(refresh).andExpect(status().isOk());
        }

        /** What a referee's screen keeps asking for. */
        void works() throws Exception {
            mvc.perform(get("/api/v1/events").header(HttpHeaders.AUTHORIZATION, "Bearer " + access))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$[0].id").value(eventId.toString()));
        }
    }

    ResultActions refresh(String token) throws Exception {
        return mvc.perform(post("/api/v1/auth/refresh")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"refreshToken\":\"%s\"}".formatted(token)));
    }

    Device referee() throws Exception {
        return new Device(mvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"arbitro2\",\"password\":\"arbitro2\"}"))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString());
    }

    Device byQr() throws Exception {
        var created = call(
                        post("/api/v1/events/" + eventId + "/temporary-access")
                                .content("{\"name\":\"Juan\",\"role\":\"REFEREE\",\"mat\":3}"),
                        "club1")
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        String link = JsonPath.read(created, "$.link");
        return new Device(mvc.perform(post("/api/v1/auth/temporary")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"%s\"}".formatted(link.substring(link.indexOf("code=") + 5))))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString());
    }

    @Test
    void bothSessionsLastTheWholePhaseThroughLostNetworkAndLateRetries() throws Exception {
        var devices = new Device[] {referee(), byQr()};

        for (int hour = 0; hour < 10; hour++) {
            for (var device : devices) {
                switch (hour) {
                    // The wifi drops while renewing: the answer is lost and it tries again 40 minutes later.
                    case 2 -> {
                        device.renewLosingTheAnswer();
                        clock.advance(Duration.ofMinutes(40));
                    }
                    // Two renewals at once (the app and a retry), the second one a few seconds later.
                    case 4 -> {
                        device.renewLosingTheAnswer();
                        clock.advance(Duration.ofSeconds(3));
                    }
                    // Lost answer and no network for three hours, well past the access token.
                    case 6 -> {
                        device.renewLosingTheAnswer();
                        clock.advance(Duration.ofHours(3));
                    }
                    default -> {}
                }
                device.renew();
                device.works();
            }
            // Every quarter of an hour the app renews its access token.
            for (int quarter = 0; quarter < 4; quarter++) {
                clock.advance(Duration.ofMinutes(15));
                for (var device : devices) {
                    device.renew();
                    device.works();
                }
            }
        }

        // The phase ends: the QR access with it, the account's own session goes on.
        call(post("/api/v1/events/" + eventId + "/phase/finish"), "club1").andExpect(status().isOk());
        refresh(devices[1].refresh).andExpect(status().isUnauthorized());
        devices[0].renew();
        devices[0].works();
    }
}
