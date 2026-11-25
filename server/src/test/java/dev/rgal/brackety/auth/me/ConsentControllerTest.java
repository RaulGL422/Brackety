package dev.rgal.brackety.auth.me;

import static dev.rgal.brackety.auth.account.ProfileType.STUDENT;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.session.SessionService.Session;
import dev.rgal.brackety.legal.LegalDocument;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

// A material change of the terms or the privacy policy asks for a new acceptance (docs/modulos/legal-paginas.md).
class ConsentControllerTest extends AuthIntegrationTest {

    private static final String ANA = "ana@example.test";

    @Autowired
    MockMvc mvc;

    @Autowired
    AuthService auth;

    @Test
    void whoAcceptedTheCurrentTextsHasNothingPending() throws Exception {
        var session = account();

        mvc.perform(as(session, get("/api/v1/me")))
                .andExpect(jsonPath("$.pendingConsents").isEmpty());
    }

    @Test
    void aChangedTextIsPendingUntilTheCurrentVersionIsAccepted() throws Exception {
        var session = account();
        acceptedBefore("TERMS", "2026-01-01");

        mvc.perform(as(session, get("/api/v1/me")))
                .andExpect(jsonPath("$.pendingConsents.length()").value(1))
                .andExpect(jsonPath("$.pendingConsents[0].document").value("terms"))
                .andExpect(jsonPath("$.pendingConsents[0].version").value(LegalDocument.TERMS.version()));

        accept(session, "terms", LegalDocument.TERMS.version())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.pendingConsents").isEmpty());
        assertThat(jdbc.sql("select count(*) from consent where document = 'TERMS' and version = ?")
                        .param(LegalDocument.TERMS.version())
                        .query(Integer.class)
                        .single())
                .isEqualTo(1);
    }

    // The text changed again while the person was reading: they read the new one.
    @Test
    void anOldVersionOrAnUnknownTextIsRefused() throws Exception {
        var session = account();
        acceptedBefore("PRIVACY", "2026-01-01");

        accept(session, "privacy", "2026-01-01")
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("LEGAL_VERSION_OUTDATED"));
        accept(session, "cookies", LegalDocument.COOKIES.version()).andExpect(status().isBadRequest());
        mvc.perform(as(session, get("/api/v1/me")))
                .andExpect(jsonPath("$.pendingConsents[0].document").value("privacy"));
    }

    // A QR referee never accepted anything: they are not stopped on the competition day.
    @Test
    void anAccountThatNeverAcceptedIsNotAsked() throws Exception {
        var session = account();
        jdbc.sql("delete from consent").update();

        mvc.perform(as(session, get("/api/v1/me")))
                .andExpect(jsonPath("$.pendingConsents").isEmpty());
    }

    /** As if the person had signed up when {@code version} was the current text. */
    private void acceptedBefore(String document, String version) {
        jdbc.sql("update consent set version = ? where document = ?")
                .param(version)
                .param(document)
                .update();
    }

    private ResultActions accept(Session session, String document, String version) throws Exception {
        return mvc.perform(as(
                session,
                post("/api/v1/me/consents")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"accepted\":[{\"document\":\"%s\",\"version\":\"%s\"}]}"
                                .formatted(document, version))));
    }

    private Session account() {
        auth.register(registration(ANA, STUDENT, "es"));
        jdbc.sql("update account set email_verified = true where email = ?")
                .param(ANA)
                .update();
        return auth.login(ANA, PASSWORD, "203.0.113.10");
    }
}
