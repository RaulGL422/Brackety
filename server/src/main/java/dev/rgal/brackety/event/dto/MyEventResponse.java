package dev.rgal.brackety.event.dto;

import dev.rgal.brackety.event.EventRole;
import java.time.LocalDate;
import java.util.Set;
import java.util.UUID;

/** An event where the caller has a role; {@code matId} is set for a referee with a mat. */
public record MyEventResponse(
        UUID id, String name, LocalDate date, Set<EventRole> roles, UUID matId, Integer matNumber) {}
