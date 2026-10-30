package dev.rgal.brackety.notifications;

import java.util.concurrent.Executor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

@Service
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);

    private final EmailSender sender;
    private final Executor executor;

    EmailService(EmailSender sender, @Qualifier("applicationTaskExecutor") Executor executor) {
        this.sender = sender;
        this.executor = executor;
    }

    // Sent after commit, so a rolled back request never mails a link that does not exist, and on another
    // thread, so the response time does not reveal whether an email went out (account enumeration).
    public void send(Email email) {
        if (!TransactionSynchronizationManager.isSynchronizationActive()) {
            executor.execute(() -> sendQuietly(email));
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                executor.execute(() -> sendQuietly(email));
            }
        });
    }

    // A failed email must never fail the request that caused it, nor tell the client anything.
    private void sendQuietly(Email email) {
        try {
            sender.send(email);
        } catch (RuntimeException e) {
            log.error("Email '{}' could not be sent: {}", email.subject(), e.getMessage());
        }
    }
}
