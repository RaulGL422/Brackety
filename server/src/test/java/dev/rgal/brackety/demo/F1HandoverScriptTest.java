package dev.rgal.brackety.demo;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.auth.SecurityConfig;
import dev.rgal.brackety.event.EventApiTest;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

/** deploy/f1-handover.sql (docs/09-despliegue.md) on the demo event, as f1-handover.sh runs it. */
class F1HandoverScriptTest extends EventApiTest {

    static final String EMAIL = "Entidad@Example.test";
    static final String NEW_PASSWORD = "a-new-long-password";

    @Autowired
    JdbcTemplate template;

    @Test
    void theClubAccountBecomesTheEntitysAndTheGenericOnesAreRetired() throws Exception {
        var outsider = outsider();
        var clubId = accountId("club1");

        run("club1", EMAIL, SecurityConfig.argon2().encode(NEW_PASSWORD));

        assertThat(accountId("entidad@example.test")).isEqualTo(clubId);
        call(get("/api/v1/events"), "entidad@example.test", NEW_PASSWORD)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(eventId.toString()));
        for (var generic : new String[] {"ayudante1", "arbitro1"}) {
            assertThatThrownBy(() -> auth.login(generic, generic, "127.0.0.1"));
            assertThat(accounts.findByEmail(generic).orElseThrow().isSuspended())
                    .isTrue();
        }
        assertThat(jdbc.sql("select count(*) from admin_audit where action = 'USER_SUSPENDED'")
                        .query(Integer.class)
                        .single())
                .isEqualTo(7);
        // Real accounts are left alone.
        assertThat(auth.login(outsider, PASSWORD, "127.0.0.1").accessToken()).isNotBlank();
    }

    @Test
    void nothingChangesWhenTheEmailIsTakenOrTheHashIsNotOne() throws Exception {
        var outsider = outsider();
        var hash = SecurityConfig.argon2().encode(NEW_PASSWORD);

        assertThatThrownBy(() -> run("club1", outsider, hash)).hasMessageContaining("already uses");
        assertThatThrownBy(() -> run("club1", EMAIL, NEW_PASSWORD)).hasMessageContaining("--superadmin-hash");
        assertThatThrownBy(() -> run("nobody", EMAIL, hash)).hasMessageContaining("No active club");
        assertThatThrownBy(() -> run("club1", "not-an-email", hash)).hasMessageContaining("Not an email");

        assertThat(auth.login("club1", "club1", "127.0.0.1").accessToken()).isNotBlank();
        assertThat(auth.login("arbitro1", "arbitro1", "127.0.0.1").accessToken())
                .isNotBlank();
    }

    /** psql fills :'name' with the quoted value; here, the same by hand. */
    private void run(String club, String email, String hash) throws IOException {
        // One string, as psql sends it: one transaction, so the checks leave nothing half done.
        var sql = Files.readString(Path.of("../deploy/f1-handover.sql"))
                .replace(":'club'", quote(club))
                .replace(":'email'", quote(email))
                .replace(":'hash'", quote(hash));
        template.execute(sql);
    }

    private static String quote(String value) {
        return "'" + value.replace("'", "''") + "'";
    }
}
