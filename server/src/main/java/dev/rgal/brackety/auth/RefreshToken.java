package dev.rgal.brackety.auth;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Instant;
import java.util.UUID;

@Entity
class RefreshToken {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private String tokenHash;
    private UUID familyId;
    private UUID accountId;
    private Instant createdAt;
    private Instant expiresAt;
    private Instant usedAt;
    private Instant revokedAt;

    protected RefreshToken() {}

    RefreshToken(String tokenHash, UUID familyId, UUID accountId, Instant now, Instant expiresAt) {
        this.tokenHash = tokenHash;
        this.familyId = familyId;
        this.accountId = accountId;
        this.createdAt = now;
        this.expiresAt = expiresAt;
    }

    UUID getFamilyId() {
        return familyId;
    }

    UUID getAccountId() {
        return accountId;
    }

    boolean isUsed() {
        return usedAt != null;
    }

    boolean isRevoked() {
        return revokedAt != null;
    }

    boolean isExpired(Instant now) {
        return !now.isBefore(expiresAt);
    }

    boolean wasUsedSince(Instant since) {
        return usedAt != null && !usedAt.isBefore(since);
    }

    void markUsed(Instant now) {
        usedAt = now;
    }
}
