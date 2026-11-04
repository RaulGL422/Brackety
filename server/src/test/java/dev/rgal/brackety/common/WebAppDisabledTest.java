package dev.rgal.brackety.common;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.auth.SecurityConfig;
import dev.rgal.brackety.auth.account.AccountRepository;
import java.time.Clock;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

// No WEB_DIR, as in Docker and production: the API serves no web and every other path needs a token.
@WebMvcTest(InfoController.class)
@Import({WebAppConfig.class, SecurityConfig.class, WebAppDisabledTest.SystemClock.class})
class WebAppDisabledTest {

    @MockitoBean
    AccountRepository accounts;

    @Autowired
    MockMvc mvc;

    @Autowired
    ApplicationContext context;

    @Test
    void servesNoWebByDefault() throws Exception {
        assertThat(context.getBeansOfType(WebAppConfig.class)).isEmpty();
        mvc.perform(get("/")).andExpect(status().isUnauthorized());
        mvc.perform(get("/login")).andExpect(status().isUnauthorized());
    }

    @TestConfiguration(proxyBeanMethods = false)
    static class SystemClock {

        @Bean
        Clock clock() {
            return Clock.systemUTC();
        }
    }
}
