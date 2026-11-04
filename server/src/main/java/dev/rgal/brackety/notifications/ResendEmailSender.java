package dev.rgal.brackety.notifications;

import java.util.List;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.web.client.RestClient;

class ResendEmailSender implements EmailSender {

    static final String BASE_URL = "https://api.resend.com";

    private final RestClient client;
    private final String from;

    ResendEmailSender(RestClient.Builder builder, String apiKey, String from) {
        this.client = builder.baseUrl(BASE_URL)
                .defaultHeader(HttpHeaders.AUTHORIZATION, "Bearer " + apiKey)
                .build();
        this.from = from;
    }

    @Override
    public void send(Email email) {
        client.post()
                .uri("/emails")
                .contentType(MediaType.APPLICATION_JSON)
                .body(new ResendRequest(from, List.of(email.to()), email.subject(), email.html(), email.text()))
                .retrieve()
                .toBodilessEntity();
    }

    record ResendRequest(String from, List<String> to, String subject, String html, String text) {}
}
