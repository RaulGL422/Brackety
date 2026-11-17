package dev.rgal.brackety.staff.dto;

import dev.rgal.brackety.event.EventRole;
import java.time.LocalDate;

/** What an invitation link offers. {@code forYou}: the signed-in account has the invited email, so it can accept. */
public record InvitationView(
        String eventName, LocalDate eventDate, String organizer, EventRole role, String email, boolean forYou) {}
