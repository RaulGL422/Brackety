package dev.rgal.brackety.staff;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface TemporaryAccessRepository extends JpaRepository<TemporaryAccess, UUID> {

    Optional<TemporaryAccess> findByTokenHash(String tokenHash);

    List<TemporaryAccess> findByEventIdOrderByCreatedAt(UUID eventId);

    List<TemporaryAccess> findByEventIdAndEndedAtIsNull(UUID eventId);

    long countByEventId(UUID eventId);
}
