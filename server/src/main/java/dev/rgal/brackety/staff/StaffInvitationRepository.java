package dev.rgal.brackety.staff;

import dev.rgal.brackety.event.EventRole;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface StaffInvitationRepository extends JpaRepository<StaffInvitation, UUID> {

    Optional<StaffInvitation> findByTokenHash(String tokenHash);

    Optional<StaffInvitation> findByEventIdAndEmailAndRoleAndAcceptedAtIsNull(
            UUID eventId, String email, EventRole role);

    List<StaffInvitation> findByEventIdAndAcceptedAtIsNullOrderBySentAt(UUID eventId);

    long countByEventIdAndAcceptedAtIsNull(UUID eventId);
}
