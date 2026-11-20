package dev.rgal.brackety.event;

import java.util.UUID;

/** Published when a phase finishes, by the club or by itself: what lived only during it ends (staff QR access). */
public record PhaseFinished(UUID eventId) {}
