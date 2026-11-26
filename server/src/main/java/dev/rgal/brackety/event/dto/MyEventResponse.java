package dev.rgal.brackety.event.dto;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventPermission;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.MeasureRequirement;
import java.time.LocalDate;
import java.util.Set;
import java.util.UUID;

/**
 * An event where the caller has a role; {@code permissions}: what they may do there (F1-7 C). {@code matId} is set for a referee with a mat.
 * {@code leagueId}, {@code leagueName} and {@code phaseNumber}: the league the event is a phase of.
 * {@code weightRequirement} and {@code heightRequirement}: whether the event asks for them (its own or its sport's).
 * {@code phaseState}: whether the club has started or finished this phase, so the app can sort the events.
 */
public record MyEventResponse(
        UUID id,
        String name,
        LocalDate date,
        Set<EventRole> roles,
        Set<EventPermission> permissions,
        UUID matId,
        Integer matNumber,
        UUID leagueId,
        String leagueName,
        int phaseNumber,
        MeasureRequirement weightRequirement,
        MeasureRequirement heightRequirement,
        Event.PhaseState phaseState) {}
