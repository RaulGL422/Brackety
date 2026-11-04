package dev.rgal.brackety.event;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface EventCategoryRepository extends JpaRepository<EventCategory, UUID> {

    List<EventCategory> findByEventIdOrderByMinAge(UUID eventId);

    // Native so this package does not depend on grouping, which depends on it.
    @Query(
            value = "select category_id from fight_group where event_id = :eventId"
                    + " union select category_id from team where event_id = :eventId",
            nativeQuery = true)
    List<UUID> findInUse(UUID eventId);
}
