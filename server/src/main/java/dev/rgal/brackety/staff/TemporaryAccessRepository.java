package dev.rgal.brackety.staff;

import jakarta.persistence.LockModeType;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;

interface TemporaryAccessRepository extends JpaRepository<TemporaryAccess, UUID> {

    // Locked so one code scanned twice at once cannot open two sessions.
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Optional<TemporaryAccess> findByTokenHash(String tokenHash);

    List<TemporaryAccess> findByEventIdOrderByCreatedAt(UUID eventId);

    List<TemporaryAccess> findByEventIdAndEndedAtIsNull(UUID eventId);

    List<TemporaryAccess> findByAccountIdAndEndedAtIsNull(UUID accountId);

    long countByEventId(UUID eventId);
}
