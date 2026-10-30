package dev.rgal.brackety.notifications;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.core.task.SyncTaskExecutor;
import org.springframework.transaction.support.TransactionSynchronizationManager;

class EmailServiceTest {

    private static final Email EMAIL = new Email("ana@example.test", "Subject", "Text", "<p>Html</p>", "https://x");

    private final CapturingEmailSender sender = new CapturingEmailSender();
    private final EmailService service = new EmailService(sender, new SyncTaskExecutor());

    @AfterEach
    void clearTransaction() {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.clearSynchronization();
        }
    }

    @Test
    void insideATransactionItWaitsForTheCommit() {
        TransactionSynchronizationManager.initSynchronization();

        service.send(EMAIL);
        assertThat(sender.sent()).isEmpty();

        TransactionSynchronizationManager.getSynchronizations().forEach(s -> s.afterCommit());
        assertThat(sender.sent()).containsExactly(EMAIL);
    }

    @Test
    void aFailingProviderNeverReachesTheCaller() {
        sender.failFromNowOn();

        service.send(EMAIL);

        assertThat(sender.sent()).isEmpty();
    }

    @Test
    void theLogSenderMasksTheRecipient() {
        assertThat(LogEmailSender.mask("ana@example.test")).isEqualTo("a***@example.test");
        assertThat(LogEmailSender.mask("broken")).isEqualTo("***");
    }

    @Test
    void resendNeedsSenderAndPublicUrl() {
        var config = new EmailConfig();

        assertThat(config.emailSender("", "", "")).isInstanceOf(LogEmailSender.class);
        assertThatThrownBy(() -> config.emailSender("re_key", "", "https://brackety.example.test"))
                .isInstanceOf(IllegalStateException.class);
        assertThat(config.emailSender("re_key", "Brackety <no-reply@example.test>", "https://brackety.example.test"))
                .isInstanceOf(ResendEmailSender.class);
    }
}
