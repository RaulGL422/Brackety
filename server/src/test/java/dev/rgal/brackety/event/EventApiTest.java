package dev.rgal.brackety.event;

import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.demo.DemoSetup;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/** Starts each test with the demo event and its accounts (password = username). */
public abstract class EventApiTest extends AuthIntegrationTest {

    @Autowired
    protected MockMvc mvc;

    @Autowired
    protected AuthService auth;

    @Autowired
    protected AccountRepository accounts;

    @Autowired
    protected DemoSetup demo;

    protected UUID eventId;

    @BeforeEach
    void seedDemo() {
        eventId = demo.seed();
    }

    protected UUID accountId(String username) {
        return accounts.findByEmail(username).orElseThrow().getId();
    }

    protected ResultActions call(MockHttpServletRequestBuilder request, String username) throws Exception {
        return call(request, username, username);
    }

    protected ResultActions call(MockHttpServletRequestBuilder request, String username, String password)
            throws Exception {
        var token = auth.login(username, password, "127.0.0.1").accessToken();
        return mvc.perform(
                request.header(HttpHeaders.AUTHORIZATION, "Bearer " + token).contentType(MediaType.APPLICATION_JSON));
    }

    /** A verified account with no role in the demo event. */
    protected String outsider() {
        var email = "outsider@example.test";
        auth.register(registration(email));
        jdbc.sql("update account set email_verified = true where email = ?")
                .param(email)
                .update();
        return email;
    }
}
