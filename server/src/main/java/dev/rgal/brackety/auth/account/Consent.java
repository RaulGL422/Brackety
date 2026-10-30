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
        PRIVACY
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

    Document getDocument() {
        return document;
    }

    String getVersion() {
        return version;
    }

    Instant getAcceptedAt() {
        return acceptedAt;
    }
}
