package dev.rgal.brackety.auth.dto;

import dev.rgal.brackety.auth.account.ProfileType;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * Everything the account holds about its owner. Each module adds its own list (registrations, results)
 * as a new field here. Never the password hash, nor the provider's {@code sub}.
 */
public record DataExport(
        Instant exportedAt,
        AccountData account,
        List<ProfileData> profiles,
        List<IdentityData> identities,
        List<ConsentData> consents) {

    public record AccountData(
            String email,
            boolean emailVerified,
            boolean hasPassword,
            LocalDate birthDate,
            String locale,
            Instant createdAt,
            Instant updatedAt) {}

    public record ProfileData(ProfileType type, boolean validated, Instant createdAt) {}

    public record IdentityData(String provider, String email, Instant linkedAt) {}

    public record ConsentData(String document, String version, Instant acceptedAt) {}
}
