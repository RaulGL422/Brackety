package dev.rgal.brackety.legal;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.auth.SecurityConfig;
import dev.rgal.brackety.auth.account.AccountRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(LegalController.class)
@Import({LegalService.class, SecurityConfig.class, LegalControllerTest.FixedClock.class})
@TestPropertySource(
        properties = {
            "brackety.legal.owner-name=Titular Ficticio",
            "brackety.legal.privacy-contact-email=privacidad@example.test"
        })
class LegalControllerTest {

    // The JWT decoder of SecurityConfig needs it; this slice has no JPA and no request carries a token.
    @MockitoBean
    AccountRepository accounts;

    @Autowired
    MockMvc mvc;

    @Test
    void listsTheDocumentsWithTheirVersionsWithoutAToken() throws Exception {
        mvc.perform(get("/api/v1/legal"))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.CACHE_CONTROL, "max-age=300, public"))
                .andExpect(jsonPath("$.privacyContactConfigured").value(true))
                .andExpect(jsonPath("$.documents.length()").value(4))
                .andExpect(jsonPath("$.documents[?(@.type == 'terms')].version").value("2026-11-04"))
                .andExpect(jsonPath("$.documents[?(@.type == 'terms')].acceptanceRequired")
                        .value(true))
                .andExpect(jsonPath("$.documents[?(@.type == 'privacy')].acceptanceRequired")
                        .value(true))
                .andExpect(jsonPath("$.documents[?(@.type == 'cookies')].acceptanceRequired")
                        .value(false))
                .andExpect(jsonPath("$.documents[?(@.type == 'legal-notice')].acceptanceRequired")
                        .value(false));
    }

    @Test
    void servesEveryTextInBothLanguagesWithThePlaceholdersFilled() throws Exception {
        for (var document : LegalDocument.values()) {
            for (var lang : LegalService.LANGS) {
                mvc.perform(get("/api/v1/legal/" + document.slug()).param("lang", lang))
                        .andExpect(status().isOk())
                        .andExpect(header().string(HttpHeaders.CACHE_CONTROL, "max-age=300, public"))
                        .andExpect(jsonPath("$.type").value(document.slug()))
                        .andExpect(jsonPath("$.version").value(document.version()))
                        .andExpect(jsonPath("$.lang").value(lang))
                        .andExpect(jsonPath("$.markdown").value(containsString(document.version())))
                        .andExpect(jsonPath("$.markdown").value(not(containsString("{{"))));
            }
        }
    }

    @Test
    void thePrivacyPolicyShowsTheOwnerAndTheContact() throws Exception {
        mvc.perform(get("/api/v1/legal/privacy").param("lang", "en"))
                .andExpect(jsonPath("$.markdown").value(containsString("Titular Ficticio")))
                .andExpect(jsonPath("$.markdown").value(containsString("privacidad@example.test")));
    }

    @Test
    void aMissingOrUnknownLanguageFallsBackToSpanish() throws Exception {
        var spanish = mvc.perform(get("/api/v1/legal/terms").param("lang", "es"))
                .andReturn()
                .getResponse()
                .getContentAsString();
        mvc.perform(get("/api/v1/legal/terms"))
                .andExpect(status().isOk())
                .andExpect(content().string(spanish));
        mvc.perform(get("/api/v1/legal/terms").param("lang", "fr"))
                .andExpect(status().isOk())
                .andExpect(content().string(spanish));
    }

    @Test
    void anUnknownTypeIsA404Problem() throws Exception {
        mvc.perform(get("/api/v1/legal/contract"))
                .andExpect(status().isNotFound())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON));
    }

    @TestConfiguration(proxyBeanMethods = false)
    static class FixedClock {

        @Bean
        Clock clock() {
            return Clock.fixed(Instant.parse("2026-11-04T10:00:00Z"), ZoneId.of("Europe/Madrid"));
        }
    }
}
