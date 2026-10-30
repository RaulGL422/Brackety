package dev.rgal.brackety.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.doReturn;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.IdentityRepository;
import dev.rgal.brackety.auth.google.FakeGoogle;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicBoolean;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.mockito.stubbing.Answer;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

class GoogleSignInControllerTest extends AuthIntegrationTest {

    private static final String REGISTRATION = """
            ,"registration":{"birthDate":"%s","profile":"HELPER",
             "acceptedTermsVersion":"2027-01","acceptedPrivacyVersion":"2027-02","locale":"es"}""";

    @Autowired
    MockMvc mvc;

    @Autowired
    FakeGoogle google;

    @Autowired
    AuthService auth;

    @MockitoSpyBean
    AccountRepository accounts;

    @MockitoSpyBean
    IdentityRepository identities;

    @Test
    void aNewUserGetsRegistrationRequiredWithTheGoogleEmail() throws Exception {
        signIn(null, google.idToken("sub-ana", "ana@example.test"), "")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("REGISTRATION_REQUIRED"))
                .andExpect(jsonPath("$.email").value("ana@example.test"))
                .andExpect(jsonPath("$.accessToken").doesNotExist())
                .andExpect(header().doesNotExist(HttpHeaders.SET_COOKIE));
    }

    @Test
    void androidGetsTheSessionInTheBody() throws Exception {
        signIn(null, google.idToken("sub-ana", "ana@example.test"), REGISTRATION.formatted("1990-05-20"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SIGNED_IN"))
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.expiresIn").value(900))
                .andExpect(jsonPath("$.refreshToken").isNotEmpty())
                .andExpect(jsonPath("$.emailVerified").value(true))
                .andExpect(jsonPath("$.replacedUnverifiedAccount").value(false))
                .andExpect(jsonPath("$.email").doesNotExist())
                .andExpect(header().doesNotExist(HttpHeaders.SET_COOKIE));
    }

    @Test
    void webGetsTheRefreshTokenOnlyInTheCookie() throws Exception {
        var token = google.idToken("sub-ana", "ana@example.test");
        signIn(null, token, REGISTRATION.formatted("1990-05-20"));

        var cookie = signIn("web", token, "")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SIGNED_IN"))
                .andExpect(jsonPath("$.refreshToken").doesNotExist())
                .andReturn()
                .getResponse()
                .getHeader(HttpHeaders.SET_COOKIE);

        assertThat(cookie)
                .startsWith(AuthController.REFRESH_COOKIE + "=")
                .contains("Path=/api/v1/auth", "Secure", "HttpOnly", "SameSite=Strict");
    }

    @Test
    void replacingAnUnverifiedAccountIsFlaggedForTheWarning() throws Exception {
        auth.register(registration("ana@example.test"));

        signIn(null, google.idToken("sub-ana", "ana@example.test"), REGISTRATION.formatted("1990-05-20"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.replacedUnverifiedAccount").value(true));
    }

    @Test
    void aVerifiedAccountIsA409ProblemWithItsCode() throws Exception {
        auth.register(registration("ana@example.test"));
        jdbc.sql("update account set email_verified = true").update();

        signIn(null, google.idToken("sub-ana", "ana@example.test"), "")
                .andExpect(status().isConflict())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.code").value("ACCOUNT_EXISTS"));
    }

    @Test
    void under14IsABadRequest() throws Exception {
        signIn(null, google.idToken("sub-kid", "kid@example.test"), REGISTRATION.formatted("2013-03-11"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.detail").value("Minimum age to register is 14."));
    }

    @Test
    void incompleteRegistrationDetailsAreABadRequest() throws Exception {
        signIn(null, google.idToken("sub-ana", "ana@example.test"), ",\"registration\":{\"birthDate\":\"1990-05-20\"}")
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON));
        assertThat(count("account")).isZero();
    }

    @Test
    void anInvalidTokenIsAGeneric401Problem() throws Exception {
        signIn(null, "not-a-google-token", "")
                .andExpect(status().isUnauthorized())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.detail").value("Google sign-in failed."));
    }

    @Test
    void aConcurrentSignUpWithTheSameGoogleAccountEndsSignedIn() throws Exception {
        var token = google.idToken("sub-ana", "ana@example.test");
        signIn(null, token, REGISTRATION.formatted("1990-05-20"));
        // As if the other request had not committed yet when this one looked: it inserts again and clashes.
        doAnswer(firstCallReturns(Optional.empty(), identities))
                .when(identities)
                .findByProviderAndSubject(any(), any());
        doAnswer(firstCallReturns(Optional.empty(), accounts)).when(accounts).lockByEmail(any());

        signIn(null, token, REGISTRATION.formatted("1990-05-20"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SIGNED_IN"))
                .andExpect(jsonPath("$.replacedUnverifiedAccount").value(false));
        assertThat(count("account")).isOne();
        assertThat(count("identity")).isOne();
    }

    @Test
    void aConcurrentSignUpWithTheSameEmailGetsTheUsualAnswerOnRetry() throws Exception {
        signIn(null, google.idToken("sub-ana", "ana@example.test"), REGISTRATION.formatted("1990-05-20"));
        doAnswer(firstCallReturns(Optional.empty(), accounts)).when(accounts).lockByEmail(any());

        signIn(null, google.idToken("sub-other", "ana@example.test"), REGISTRATION.formatted("1990-05-20"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ACCOUNT_EXISTS"));
    }

    @Test
    void aClashThatPersistsAfterTheRetryIsAGeneric409() throws Exception {
        signIn(null, google.idToken("sub-ana", "ana@example.test"), REGISTRATION.formatted("1990-05-20"));
        doReturn(Optional.empty()).when(accounts).lockByEmail(any());

        signIn(null, google.idToken("sub-other", "ana@example.test"), REGISTRATION.formatted("1990-05-20"))
                .andExpect(status().isConflict())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.code").doesNotExist())
                .andExpect(jsonPath("$.detail").value("Another sign-in for this account is in progress. Try again."));
        assertThat(count("account")).isOne();
    }

    // The spies delegate to the real repository through their default answer.
    private static Answer<Object> firstCallReturns(Object value, Object spy) {
        var real = Mockito.mockingDetails(spy).getMockCreationSettings().getDefaultAnswer();
        var first = new AtomicBoolean(true);
        return invocation -> first.getAndSet(false) ? value : real.answer(invocation);
    }

    // The dev token endpoint only exists in the local runner (test sources), never in this app.
    @Test
    void theDevTokenEndpointDoesNotExistOutsideTheLocalRunner() throws Exception {
        mvc.perform(post("/api/v1/auth/dev/google-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"subject\":\"x\",\"email\":\"x@example.test\"}"))
                .andExpect(status().isNotFound());
    }

    private ResultActions signIn(String client, String idToken, String registration) throws Exception {
        var request = post("/api/v1/auth/google")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"idToken\":\"%s\"%s}".formatted(idToken, registration));
        if (client != null) {
            request.header(AuthController.CLIENT_HEADER, client);
        }
        return mvc.perform(request);
    }
}
