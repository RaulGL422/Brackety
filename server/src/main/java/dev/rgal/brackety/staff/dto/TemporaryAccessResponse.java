package dev.rgal.brackety.staff.dto;

import dev.rgal.brackety.event.EventRole;
import java.time.Instant;
import java.util.UUID;

/**
 * A QR access, as the club sees it. {@code signIn}: the temporary account's sign-in; {@code waiting}: its code is
 * still unused; {@code signedInAt}: when it was used (the club's confirmation); {@code link} and {@code password}:
 * only right after creating or renewing it, to draw the QR and to sign in again by hand.
 */
public record TemporaryAccessResponse(
        UUID id,
        UUID accountId,
        String name,
        String signIn,
        String password,
        EventRole role,
        Integer mat,
        boolean waiting,
        Instant signedInAt,
        boolean ended,
        String link) {}
