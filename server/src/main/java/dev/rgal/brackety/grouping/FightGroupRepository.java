package dev.rgal.brackety.grouping;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

public interface FightGroupRepository extends JpaRepository<FightGroup, UUID> {

    List<FightGroup> findByEventId(UUID eventId);

    List<FightGroup> findByMatIdOrderByNumber(UUID matId);

    @Query("select coalesce(max(g.number), 0) from FightGroup g where g.eventId = :eventId")
    int maxNumber(UUID eventId);

    // In the database, deleting a group takes its members, matches and their actions with it.
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("delete from FightGroup g where g.id = :groupId")
    void deleteNow(UUID groupId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("delete from FightGroup g where g.eventId = :eventId")
    int deleteByEvent(UUID eventId);
}
