package dev.rgal.brackety.league;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

public interface CategoryPodiumRepository extends JpaRepository<CategoryPodium, UUID> {

    List<CategoryPodium> findByLeagueIdOrderByCategoryName(UUID leagueId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("delete from CategoryPodium p where p.leagueId = :leagueId")
    void deleteByLeague(UUID leagueId);
}
