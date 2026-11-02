package dev.rgal.brackety.auth.account;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Instant;
import java.util.UUID;

@Entity
public class Consent {

    public enum Document {
        TERMS,
        PRIVACY,
        // An organizer is of legal age and represents the organization; versioned as the terms it was accepted with.
        ORGANIZER_DECLARATION
    }

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID accountId;

    @Enumerated(EnumType.STRING)
    private Document document;

    private String version;
    private Instant acceptedAt;

    protected Consent() {}

    public Consent(UUID accountId, Document document, String version, Instant acceptedAt) {
        this.accountId = accountId;
        this.document = document;
        this.version = version;
        this.acceptedAt = acceptedAt;
    }

    public Document getDocument() {
        return document;
    }

    public String getVersion() {
        return version;
    }

    public Instant getAcceptedAt() {
        return acceptedAt;
    }
}
