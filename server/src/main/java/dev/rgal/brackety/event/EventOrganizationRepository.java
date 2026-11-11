package dev.rgal.brackety.event;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface EventOrganizationRepository extends JpaRepository<EventOrganization, UUID> {

    List<EventOrganization> findByEventIdOrderByName(UUID eventId);

    // Native so this package does not depend on participant, which depends on it.
    @Query(
            value = "select distinct organization_id from participant"
                    + " where event_id = :eventId and organization_id is not null",
            nativeQuery = true)
    List<UUID> findInUse(UUID eventId);
}
