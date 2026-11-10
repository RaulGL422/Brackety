package dev.rgal.brackety.grouping;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

public interface TeamRepository extends JpaRepository<Team, UUID> {

    List<Team> findByEventId(UUID eventId);

    List<Team> findByCategoryIdAndGhostFalseOrderByNumber(UUID categoryId);

    @Query("select coalesce(max(t.number), 0) from Team t where t.eventId = :eventId")
    int maxNumber(UUID eventId);

    // Their members go with them in the database.
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("delete from Team t where t.eventId = :eventId")
    int deleteByEvent(UUID eventId);
}
