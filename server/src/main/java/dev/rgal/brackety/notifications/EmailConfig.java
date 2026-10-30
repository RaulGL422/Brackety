package dev.rgal.brackety.notifications;

import java.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

@Configuration(proxyBeanMethods = false)
class EmailConfig {

    private static final Logger log = LoggerFactory.getLogger(EmailConfig.class);

    @Bean
    EmailSender emailSender(
            @Value("${brackety.email.resend-api-key}") String apiKey,
            @Value("${brackety.email.from}") String from,
            @Value("${brackety.public-base-url}") String publicBaseUrl) {
        if (apiKey.isBlank()) {
            log.warn("RESEND_API_KEY is empty: emails are only written to the log");
            return new LogEmailSender();
        }
        if (from.isBlank() || publicBaseUrl.isBlank()) {
            throw new IllegalStateException("EMAIL_FROM and PUBLIC_BASE_URL are required when RESEND_API_KEY is set");
        }
        var timeouts = new SimpleClientHttpRequestFactory();
        timeouts.setConnectTimeout(Duration.ofSeconds(5));
        timeouts.setReadTimeout(Duration.ofSeconds(10));
        return new ResendEmailSender(RestClient.builder().requestFactory(timeouts), apiKey, from);
    }
}
