package dev.rgal.brackety.event;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface EventStaffRepository extends JpaRepository<EventStaff, UUID> {

    List<EventStaff> findByAccountId(UUID accountId);

    List<EventStaff> findByEventId(UUID eventId);

    List<EventStaff> findByEventIdAndAccountId(UUID eventId, UUID accountId);

    List<EventStaff> findByEventIdAndRole(UUID eventId, EventRole role);

    /** Without the accounts let in by QR, which belong to this phase only (a new phase does not copy them). */
    @Query(value = """
            select s.* from event_staff s join account a on a.id = s.account_id
            where s.event_id = :eventId and not a.temporary""", nativeQuery = true)
    List<EventStaff> findLastingByEventId(UUID eventId);
}
