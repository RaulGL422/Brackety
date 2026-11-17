package dev.rgal.brackety.devdata;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.auth.admin.CloudflareAccess;
import dev.rgal.brackety.auth.admin.FakeCloudflareAccess;
import dev.rgal.brackety.event.EventApiTest;
import dev.rgal.debug.DebugConfig;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;

/** The app without {@link DebugConfig}, as the production image runs it: the debug API does not exist. */
class ProductionHasNoDebugTest extends EventApiTest {

    @Autowired
    FakeCloudflareAccess cloudflare;

    @Test
    void theDebugPathsAreNotFoundEvenForTheSuperadmin() throws Exception {
        var body = mvc.perform(post("/api/v1/admin/auth/login")
                        .header(CloudflareAccess.HEADER, cloudflare.assertion())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","password":"%s"}""".formatted(SUPERADMIN_EMAIL, PASSWORD)))
                .andReturn()
                .getResponse()
                .getContentAsString();
        String token = JsonPath.read(body, "$.accessToken");
        mvc.perform(get("/api/v1/admin/dev/scenarios")
                        .header(CloudflareAccess.HEADER, cloudflare.assertion())
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isNotFound());
        mvc.perform(get("/api/v1/debug")).andExpect(status().isNotFound());
    }
}
