package dev.rgal.brackety.event;

import dev.rgal.brackety.common.Names;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface EventOrganizationRepository extends JpaRepository<EventOrganization, UUID> {

    @Query("select o from EventOrganization o join fetch o.organization c where o.eventId = :eventId")
    List<EventOrganization> findWithOrganizationByEventId(UUID eventId);

    /** By club name, the Spanish way on every server ({@link Names#ORDER}). */
    default List<EventOrganization> findByEventIdOrderByName(UUID eventId) {
        return findWithOrganizationByEventId(eventId).stream()
                .sorted(Comparator.comparing(EventOrganization::getName, Names.ORDER))
                .toList();
    }

    // Native so this package does not depend on participant, which depends on it.
    @Query(
            value = "select distinct organization_id from participant"
                    + " where event_id = :eventId and organization_id is not null",
            nativeQuery = true)
    List<UUID> findInUse(UUID eventId);
}
