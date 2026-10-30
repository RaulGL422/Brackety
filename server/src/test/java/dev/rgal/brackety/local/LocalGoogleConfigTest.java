package dev.rgal.brackety.local;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.auth.google.FakeGoogle;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest(
        properties = {
            "brackety.auth.google-client-ids=" + FakeGoogle.CLIENT_ID,
            "brackety.auth.unverified-purge-initial-delay=P3650D"
        })
@AutoConfigureMockMvc
@Import({EmbeddedPostgresConfig.class, LocalGoogleConfig.class})
class LocalGoogleConfigTest {

    @Autowired
    MockMvc mvc;

    @Test
    void aDevTokenSignsInWithGoogle() throws Exception {
        var response = mvc.perform(post("/api/v1/auth/dev/google-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"subject\":\"dev-sub\",\"email\":\"dev@example.test\"}"))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        mvc.perform(post("/api/v1/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"idToken\":\"%s\"}".formatted(JsonPath.<String>read(response, "$.idToken"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("REGISTRATION_REQUIRED"))
                .andExpect(jsonPath("$.email").value("dev@example.test"));
    }
}
