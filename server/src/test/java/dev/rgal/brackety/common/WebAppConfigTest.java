package dev.rgal.brackety.common;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.forwardedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.auth.SecurityConfig;
import dev.rgal.brackety.auth.account.AccountRepository;
import java.time.Clock;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextImpl;
import org.springframework.security.web.context.RequestAttributeSecurityContextRepository;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(InfoController.class)
@Import({WebAppConfig.class, SecurityConfig.class, WebAppConfigTest.SystemClock.class})
@TestPropertySource(properties = "brackety.web-dir=src/test/resources/web-fixture")
class WebAppConfigTest {

    private static final String INDEX_TEXT = "brackety-web-fixture";
    private static final String SIGNED_IN = RequestAttributeSecurityContextRepository.DEFAULT_REQUEST_ATTR_NAME;

    // The JWT decoder of SecurityConfig needs it; this slice has no JPA.
    @MockitoBean
    AccountRepository accounts;

    @Autowired
    MockMvc mvc;

    @Test
    void servesAFileWithoutAuthentication() throws Exception {
        mvc.perform(get("/main.dart.js"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("fixture")))
                .andExpect(header().string("Cache-Control", "no-cache"));
    }

    @Test
    void fallsBackToIndexForAppPaths() throws Exception {
        mvc.perform(get("/club/x"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString(INDEX_TEXT)))
                .andExpect(header().string("Cache-Control", "no-cache"));
        mvc.perform(get("/login")).andExpect(content().string(containsString(INDEX_TEXT)));
    }

    @Test
    void forwardsTheRootToIndex() throws Exception {
        mvc.perform(get("/")).andExpect(status().isOk()).andExpect(forwardedUrl("/index.html"));
    }

    @Test
    void leavesTheApiAsItWas() throws Exception {
        mvc.perform(get("/api/v1/info"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("brackety"));
        mvc.perform(get("/api/v1/unknown")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/unknown").requestAttr(SIGNED_IN, signedIn())).andExpect(status().isNotFound());
        mvc.perform(get("/actuator").requestAttr(SIGNED_IN, signedIn())).andExpect(status().isNotFound());
    }

    // A signed-in request without minting a token: the stateless chains read the context from this attribute.
    private static SecurityContextImpl signedIn() {
        return new SecurityContextImpl(UsernamePasswordAuthenticationToken.authenticated("someone", null, List.of()));
    }

    @TestConfiguration(proxyBeanMethods = false)
    static class SystemClock {

        @Bean
        Clock clock() {
            return Clock.systemUTC();
        }
    }
}
