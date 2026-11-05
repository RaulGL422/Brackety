package dev.rgal.brackety.event;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EventStaffRepository extends JpaRepository<EventStaff, UUID> {

    List<EventStaff> findByAccountId(UUID accountId);

    List<EventStaff> findByEventId(UUID eventId);

    List<EventStaff> findByEventIdAndAccountId(UUID eventId, UUID accountId);

    List<EventStaff> findByEventIdAndRole(UUID eventId, EventRole role);
}
