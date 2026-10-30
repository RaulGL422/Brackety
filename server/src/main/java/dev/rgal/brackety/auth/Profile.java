package dev.rgal.brackety.auth;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Instant;
import java.util.UUID;

@Entity
class Profile {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID accountId;

    @Enumerated(EnumType.STRING)
    private ProfileType type;

    // Only meaningful for organizers (CLUB, EXTERNAL_ENTITY): the superadmin validates them.
    private boolean validated;

    private Instant createdAt;

    protected Profile() {}

    Profile(UUID accountId, ProfileType type, Instant now) {
        this.accountId = accountId;
        this.type = type;
        this.createdAt = now;
    }

    ProfileType getType() {
        return type;
    }

    boolean isValidated() {
        return validated;
    }
}
