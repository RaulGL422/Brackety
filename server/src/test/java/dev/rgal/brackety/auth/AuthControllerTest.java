package dev.rgal.brackety.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.endsWith;
import static org.hamcrest.Matchers.matchesPattern;
import static org.mockito.Mockito.doReturn;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import jakarta.servlet.http.Cookie;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

class AuthControllerTest extends AuthIntegrationTest {

    private static final String REGISTER_JSON = """
            {"email":"%s","password":"%s","birthDate":"%s","profile":"CLUB",
             "acceptedTermsVersion":"2027-01","acceptedPrivacyVersion":"2027-02","locale":"es"}""";

    @Autowired
    MockMvc mvc;

    @MockitoSpyBean
    AccountRepository accounts;

    @Test
    void registerAndDuplicateGetTheSameEmptyAccepted() throws Exception {
        var body = REGISTER_JSON.formatted("ana@example.test", PASSWORD, "1990-05-20");

        var first = register(body).andExpect(status().isAccepted()).andReturn().getResponse();
        var second = register(body).andExpect(status().isAccepted()).andReturn().getResponse();

        assertThat(first.getContentAsString()).isEmpty();
        assertThat(second.getContentAsString()).isEqualTo(first.getContentAsString());
        assertThat(count("account")).isOne();
    }

    @Test
    void concurrentDuplicateRegistrationIsStillAccepted() throws Exception {
        var body = REGISTER_JSON.formatted("ana@example.test", PASSWORD, "1990-05-20");
        register(body).andExpect(status().isAccepted());
        doReturn(false).when(accounts).existsByEmail("ana@example.test");

        register(body).andExpect(status().isAccepted());

        assertThat(count("account")).isOne();
    }

    @Test
    void rejectsAShortPassword() throws Exception {
        register(REGISTER_JSON.formatted("ana@example.test", "123456789", "1990-05-20"))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON));
        assertThat(count("account")).isZero();
    }

    @Test
    void rejectsUnder14() throws Exception {
        register(REGISTER_JSON.formatted("kid@example.test", PASSWORD, "2013-03-11"))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON));
    }

    @Test
    void failedLoginIsAGenericProblem() throws Exception {
        login(null, "nobody@example.test")
                .andExpect(status().isUnauthorized())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.detail").value("Invalid email or password."));
    }

    @Test
    void lockedLoginIsA429ProblemWithTheLockId() throws Exception {
        for (int i = 0; i < 5; i++) {
            login(null, "nobody@example.test").andExpect(status().isUnauthorized());
        }

        login(null, "nobody@example.test")
                .andExpect(status().isTooManyRequests())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.lockId").value(matchesPattern("L-[2-9A-HJKMNP-Z]{6}")));
    }

    @Test
    void webGetsTheRefreshTokenOnlyInAStrictHttpOnlyCookie() throws Exception {
        registerAna();

        var response = login("web", "ana@example.test")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.expiresIn").value(900))
                .andExpect(jsonPath("$.refreshToken").doesNotExist())
                .andReturn()
                .getResponse();

        assertThat(response.getHeader(HttpHeaders.SET_COOKIE))
                .startsWith(AuthController.REFRESH_COOKIE + "=")
                .contains("Path=/api/v1/auth", "Max-Age=2592000", "Secure", "HttpOnly", "SameSite=Strict");
    }

    @Test
    void androidGetsTheRefreshTokenInTheBody() throws Exception {
        registerAna();

        login(null, "ana@example.test")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.refreshToken").isNotEmpty())
                .andExpect(header().doesNotExist(HttpHeaders.SET_COOKIE));
    }

    @Test
    void webRefreshesWithTheCookieAndGetsANewOne() throws Exception {
        registerAna();
        var cookie =
                login("web", "ana@example.test").andReturn().getResponse().getCookie(AuthController.REFRESH_COOKIE);

        var renewed = mvc.perform(post("/api/v1/auth/refresh")
                        .header(AuthController.CLIENT_HEADER, "web")
                        .cookie(cookie))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.refreshToken").doesNotExist())
                .andReturn()
                .getResponse()
                .getCookie(AuthController.REFRESH_COOKIE);

        assertThat(renewed.getValue()).isNotBlank().isNotEqualTo(cookie.getValue());
    }

    @Test
    void aCookieRefreshNeverReturnsTheTokenInTheBody() throws Exception {
        registerAna();
        var cookie =
                login("web", "ana@example.test").andReturn().getResponse().getCookie(AuthController.REFRESH_COOKIE);

        mvc.perform(post("/api/v1/auth/refresh").cookie(cookie))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.refreshToken").doesNotExist())
                .andExpect(header().exists(HttpHeaders.SET_COOKIE));
    }

    @Test
    void androidRefreshesWithTheBody() throws Exception {
        registerAna();
        var refresh = refreshTokenOf(login(null, "ana@example.test"));

        mvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"%s\"}".formatted(refresh)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.refreshToken").isNotEmpty());
    }

    @Test
    void reusedRefreshIsUnauthorized() throws Exception {
        registerAna();
        var refresh = refreshTokenOf(login(null, "ana@example.test"));
        var body = "{\"refreshToken\":\"%s\"}".formatted(refresh);
        mvc.perform(post("/api/v1/auth/refresh")
                .contentType(MediaType.APPLICATION_JSON)
                .content(body));

        mvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void logoutClearsTheCookieAndRevokesTheSession() throws Exception {
        registerAna();
        var cookie =
                login("web", "ana@example.test").andReturn().getResponse().getCookie(AuthController.REFRESH_COOKIE);

        var cleared = mvc.perform(post("/api/v1/auth/logout").cookie(cookie))
                .andExpect(status().isNoContent())
                .andReturn()
                .getResponse()
                .getHeader(HttpHeaders.SET_COOKIE);

        assertThat(cleared).startsWith(AuthController.REFRESH_COOKIE + "=;").contains("Max-Age=0", "Path=/api/v1/auth");
        mvc.perform(post("/api/v1/auth/refresh").cookie(new Cookie(AuthController.REFRESH_COOKIE, cookie.getValue())))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void protectedEndpointNeedsAValidAccessToken() throws Exception {
        registerAna();
        var accessToken = JsonPath.<String>read(
                login(null, "ana@example.test").andReturn().getResponse().getContentAsString(), "$.accessToken");

        mvc.perform(get("/api/v1/test/whoami"))
                .andExpect(status().isUnauthorized())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(header().exists(HttpHeaders.WWW_AUTHENTICATE));
        mvc.perform(get("/api/v1/test/whoami").header(HttpHeaders.AUTHORIZATION, "Bearer not-a-jwt"))
                .andExpect(status().isUnauthorized())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON));
        mvc.perform(get("/api/v1/test/whoami").header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken))
                .andExpect(status().isOk())
                .andExpect(content().string(endsWith("[CLUB]")));

        clock.advance(Duration.ofMinutes(15).plusSeconds(1));
        mvc.perform(get("/api/v1/test/whoami").header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void publicEndpointsStayOpen() throws Exception {
        mvc.perform(get("/api/v1/info")).andExpect(status().isOk());
        mvc.perform(get("/actuator/health")).andExpect(status().isOk());
    }

    private void registerAna() throws Exception {
        register(REGISTER_JSON.formatted("ana@example.test", PASSWORD, "1990-05-20"))
                .andExpect(status().isAccepted());
    }

    private ResultActions register(String body) throws Exception {
        return mvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(body));
    }

    private ResultActions login(String client, String email) throws Exception {
        var request = post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"%s\",\"password\":\"%s\"}".formatted(email, PASSWORD));
        if (client != null) {
            request.header(AuthController.CLIENT_HEADER, client);
        }
        return mvc.perform(request);
    }

    private static String refreshTokenOf(ResultActions login) throws Exception {
        return JsonPath.read(login.andReturn().getResponse().getContentAsString(), "$.refreshToken");
    }
}
