package dev.rgal.brackety.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import jakarta.servlet.http.Cookie;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

// The sports hall laptop serves plain http (start-event.ps1): a Secure cookie would never come back on reload.
@TestPropertySource(properties = "brackety.auth.refresh-cookie-secure=false")
class HallRefreshCookieTest extends AuthIntegrationTest {

    @Autowired
    MockMvc mvc;

    @Test
    void cookieWithoutSecureStillRefreshesAndRotates() throws Exception {
        mvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"ana@example.test","password":"%s","birthDate":"1990-05-20",
                                 "profile":"HELPER","acceptedTermsVersion":"%s","acceptedPrivacyVersion":"%s",
                                 "locale":"es"}""".formatted(PASSWORD, TERMS_VERSION, PRIVACY_VERSION)))
                .andExpect(status().isAccepted());
        var login = mvc.perform(post("/api/v1/auth/login")
                        .header(AuthController.CLIENT_HEADER, "web")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"ana@example.test\",\"password\":\"%s\"}".formatted(PASSWORD)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse();
        assertThat(login.getHeader(HttpHeaders.SET_COOKIE))
                .contains("HttpOnly", "SameSite=Strict", "Path=/api/v1/auth")
                .doesNotContain("Secure");

        var refreshed = mvc.perform(post("/api/v1/auth/refresh")
                        .cookie(new Cookie(
                                AuthController.REFRESH_COOKIE,
                                login.getCookie(AuthController.REFRESH_COOKIE).getValue())))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse();
        assertThat(refreshed.getHeader(HttpHeaders.SET_COOKIE)).doesNotContain("Secure");
    }
}
