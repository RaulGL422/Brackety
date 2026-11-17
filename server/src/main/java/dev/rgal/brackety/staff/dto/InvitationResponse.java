package dev.rgal.brackety.staff.dto;

import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.staff.StaffInvitation;
import java.time.Instant;
import java.util.UUID;

/** A pending invitation, as the club sees it. {@code expired}: the link no longer works; inviting again renews it. */
public record InvitationResponse(UUID id, String email, EventRole role, Instant sentAt, boolean expired) {

    public static InvitationResponse of(StaffInvitation invitation, Instant now) {
        return new InvitationResponse(
                invitation.getId(),
                invitation.getEmail(),
                invitation.getRole(),
                invitation.getSentAt(),
                !now.isBefore(invitation.getExpiresAt()));
    }
}
