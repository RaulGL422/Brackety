package dev.rgal.brackety.scoreboard;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface RejectedOpRepository extends JpaRepository<RejectedOp, UUID> {

    Optional<RejectedOp> findByOpId(UUID opId);

    int countByMatchId(UUID matchId);

    List<RejectedOp> findByMatchIdAndResolutionIsNullOrderByPosition(UUID matchId);
}
