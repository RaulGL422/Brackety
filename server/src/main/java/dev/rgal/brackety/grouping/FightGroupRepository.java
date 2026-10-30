package dev.rgal.brackety.grouping;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface FightGroupRepository extends JpaRepository<FightGroup, UUID> {

    List<FightGroup> findByEventId(UUID eventId);

    List<FightGroup> findByMatIdOrderByNumber(UUID matId);

    @Query("select coalesce(max(g.number), 0) from FightGroup g where g.eventId = :eventId")
    int maxNumber(UUID eventId);
}
