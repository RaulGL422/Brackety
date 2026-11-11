package dev.rgal.brackety.grouping;

import jakarta.persistence.LockModeType;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;

public interface MatchRepository extends JpaRepository<Match, UUID> {

    List<Match> findByEventId(UUID eventId);

    // One referee writes a match, but a double tap must not interleave two events.
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select m from Match m where m.id = :matchId")
    Optional<Match> lockById(UUID matchId);

    // In id order, so two writers locking the same matches never wait on each other in a cycle.
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select m from Match m where m.groupId = :groupId order by m.id")
    List<Match> lockByGroupId(UUID groupId);
}
