package dev.rgal.brackety.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** What the superadmin sees of accounts (docs/modulos/superadmin-reportes.md). */
public final class AdminUserDtos {

    private AdminUserDtos() {}

    public record UserPage(List<UserRow> items, int page, int size, long total) {}

    /**
     * {@code status}: ACTIVE or DELETED (waiting for the purge); {@code profiles} sorted; {@code organization}: the
     * organizer's name, if it has one.
     */
    public record UserRow(
            UUID id,
            String email,
            Instant createdAt,
            boolean emailVerified,
            String status,
            boolean suspended,
            List<String> profiles,
            String organization,
            // Sees the Connection screen in the app.
            boolean support) {}

    /**
     * {@code signInMethods}: PASSWORD and the linked providers; {@code lastSignIn}: the newest session; {@code
     * deletesOn}: the purge day of a deleted account.
     */
    public record UserDetail(
            UserRow user,
            List<String> signInMethods,
            int ownedEvents,
            int staffEvents,
            Instant lastSignIn,
            Instant suspendedAt,
            LocalDate deletesOn) {}

    /** Support on or off for an account, with the reason the audit keeps. */
    public record SupportRequest(
            boolean enabled, @NotBlank @Size(max = 300) String reason) {}
}
