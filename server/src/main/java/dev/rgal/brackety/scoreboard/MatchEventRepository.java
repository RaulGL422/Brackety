package dev.rgal.brackety.scoreboard;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

public interface MatchEventRepository extends JpaRepository<MatchEvent, UUID> {

    List<MatchEvent> findByMatchIdOrderByPosition(UUID matchId);

    boolean existsByOpId(UUID opId);

    @Query("select e from MatchEvent e where e.matchId in"
            + " (select m.id from Match m where m.eventId = :eventId) order by e.matchId, e.position")
    List<MatchEvent> findByEventId(UUID eventId);

    // One statement: an undo points at the action it undoes, so row by row the order would matter.
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("delete from MatchEvent e where e.matchId = :matchId")
    void deleteByMatchId(UUID matchId);
}
