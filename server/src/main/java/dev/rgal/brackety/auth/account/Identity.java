package dev.rgal.brackety.auth.account;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Instant;
import java.util.UUID;

/** A sign-in with an external provider, found by the provider's {@code sub}, never by email. */
@Entity
public class Identity {

    public enum Provider {
        GOOGLE
    }

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID accountId;

    @Enumerated(EnumType.STRING)
    private Provider provider;

    private String subject;
    private String providerEmail;
    private Instant createdAt;

    protected Identity() {}

    public Identity(UUID accountId, Provider provider, String subject, String providerEmail, Instant now) {
        this.accountId = accountId;
        this.provider = provider;
        this.subject = subject;
        this.providerEmail = providerEmail;
        this.createdAt = now;
    }

    public UUID getAccountId() {
        return accountId;
    }

    public Provider getProvider() {
        return provider;
    }

    public String getProviderEmail() {
        return providerEmail;
    }

    public Instant getLinkedAt() {
        return createdAt;
    }
}
