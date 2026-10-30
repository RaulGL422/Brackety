package dev.rgal.brackety.notifications;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.content;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

class ResendEmailSenderTest {

    private static final Email EMAIL =
            new Email("ana@example.test", "Subject", "Text https://x", "<p>Html</p>", "https://x");

    private final RestClient.Builder builder = RestClient.builder();
    private final MockRestServiceServer server =
            MockRestServiceServer.bindTo(builder).build();
    private final ResendEmailSender sender =
            new ResendEmailSender(builder, "re_test_key", "Brackety <no-reply@example.test>");

    @Test
    void postsTheEmailToResendWithTheApiKey() {
        server.expect(requestTo("https://api.resend.com/emails"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header(HttpHeaders.AUTHORIZATION, "Bearer re_test_key"))
                .andExpect(content().json("""
                        {"from":"Brackety <no-reply@example.test>","to":["ana@example.test"],
                         "subject":"Subject","html":"<p>Html</p>","text":"Text https://x"}"""))
                .andRespond(withSuccess("{\"id\":\"1\"}", MediaType.APPLICATION_JSON));

        sender.send(EMAIL);

        server.verify();
    }

    @Test
    void aResendErrorIsThrownForTheCallerToLog() {
        server.expect(requestTo("https://api.resend.com/emails")).andRespond(withServerError());

        assertThatThrownBy(() -> sender.send(EMAIL)).isInstanceOf(RestClientException.class);
    }
}
