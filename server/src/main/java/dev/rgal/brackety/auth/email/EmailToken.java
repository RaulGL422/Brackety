package dev.rgal.brackety.auth.email;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

@Entity
public class EmailToken {

    public enum Purpose {
        VERIFY_EMAIL(Duration.ofHours(24)),
        RESET_PASSWORD(Duration.ofHours(1)),
        CHANGE_EMAIL(Duration.ofHours(24));

        final Duration ttl;

        Purpose(Duration ttl) {
            this.ttl = ttl;
        }
    }

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private String tokenHash;
    private UUID accountId;

    @Enumerated(EnumType.STRING)
    private Purpose purpose;

    private Instant createdAt;
    private Instant expiresAt;
    private String newEmail;

    protected EmailToken() {}

    EmailToken(String tokenHash, UUID accountId, Purpose purpose, String newEmail, Instant now) {
        this.tokenHash = tokenHash;
        this.accountId = accountId;
        this.purpose = purpose;
        this.newEmail = newEmail;
        this.createdAt = now;
        this.expiresAt = now.plus(purpose.ttl);
    }

    UUID getAccountId() {
        return accountId;
    }

    String getNewEmail() {
        return newEmail;
    }

    boolean isUsable(Purpose expected, Instant now) {
        return purpose == expected && now.isBefore(expiresAt);
    }
}
