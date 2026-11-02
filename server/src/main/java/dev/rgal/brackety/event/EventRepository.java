package dev.rgal.brackety.event;

import jakarta.persistence.LockModeType;
import java.util.Collection;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;

public interface EventRepository extends JpaRepository<Event, UUID> {

    boolean existsByOwnerAccountId(UUID ownerAccountId);

    // Serializes group creation in one event: mat choice and group numbers need a stable view.
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select e from Event e where e.id = :eventId")
    Optional<Event> lockById(UUID eventId);

    // Native so this package does not depend on grouping, which depends on it.
    @Query(
            value = "select exists(select 1 from fight_group where event_id = :eventId)"
                    + " or exists(select 1 from team where event_id = :eventId)",
            nativeQuery = true)
    boolean hasGroupsOrTeams(UUID eventId);

    @Query(value = "select exists(select 1 from fight_group where mat_id in (:matIds))", nativeQuery = true)
    boolean hasGroupsOnMats(Collection<UUID> matIds);
}
