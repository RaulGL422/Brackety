package dev.rgal.brackety.legal;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.context.support.ResourceBundleMessageSource;

class LegalServiceTest {

    @Test
    void withoutOwnerOrContactTheTextsSayTheyAreNotConfiguredYet() {
        var legal = new LegalService(messages(), "", " ");

        assertThat(legal.isPrivacyContactConfigured()).isFalse();
        assertThat(legal.text("privacy", "es").orElseThrow().markdown())
                .contains("(pendiente de configurar)")
                .doesNotContain("{{");
        assertThat(legal.text("privacy", "en").orElseThrow().markdown())
                .contains("(not configured yet)")
                .doesNotContain("{{");
    }

    @Test
    void anUnknownTypeIsEmpty() {
        assertThat(new LegalService(messages(), "Titular", "p@example.test").text("contract", "es"))
                .isEmpty();
    }

    private static ResourceBundleMessageSource messages() {
        var messages = new ResourceBundleMessageSource();
        messages.setBasename("i18n/messages");
        messages.setDefaultEncoding("UTF-8");
        messages.setFallbackToSystemLocale(false);
        return messages;
    }
}
