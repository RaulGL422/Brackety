package dev.rgal.brackety.event;

import java.util.UUID;

/**
 * Published when a phase is created from another one, inside the same transaction: what lives while a phase is open
 * goes on to the new one (staff QR access, Raul 2026-11-23).
 */
public record PhaseCreated(UUID fromEventId, UUID eventId) {}
