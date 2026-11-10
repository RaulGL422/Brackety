package dev.rgal.brackety.scoreboard;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

interface RejectedOpRepository extends JpaRepository<RejectedOp, UUID> {

    Optional<RejectedOp> findByOpId(UUID opId);

    int countByMatchId(UUID matchId);

    List<RejectedOp> findByMatchIdAndResolutionIsNullOrderByPosition(UUID matchId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("delete from RejectedOp r where r.matchId = :matchId")
    void deleteByMatchId(UUID matchId);
}
