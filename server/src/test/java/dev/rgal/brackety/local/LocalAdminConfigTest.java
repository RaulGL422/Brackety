package dev.rgal.brackety.local;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

// Same superadmin as application-local.properties (password brackety-demo).
@SpringBootTest(
        properties = {
            LocalAdminConfig.SKIP_ACCESS + "=true",
            "brackety.superadmin.email=superadmin@example.test",
            "brackety.superadmin.password-hash="
                    + "$argon2id$v=19$m=19456,t=2,p=1$qty4Hpx8trIozbxqxr56OQ$0NiOranNveRkXNK0Vqguif+/ertv6ImRz9eUqDI2QHM",
            "brackety.auth.unverified-purge-initial-delay=P3650D",
            "brackety.auth.deleted-purge-initial-delay=P3650D"
        })
@AutoConfigureMockMvc
@Import({EmbeddedPostgresConfig.class, LocalAdminConfig.class})
class LocalAdminConfigTest {

    @Autowired
    MockMvc mvc;

    @Test
    void theLocalSuperadminLogsInWithoutCloudflareAccess() throws Exception {
        mvc.perform(post("/api/v1/admin/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"superadmin@example.test\",\"password\":\"brackety-demo\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty());
    }
}
