package dev.rgal.brackety.participant;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ParticipantRepository extends JpaRepository<Participant, UUID> {

    List<Participant> findByEventIdOrderByFirstNameAscLastNameAsc(UUID eventId);

    // Native so this package does not depend on grouping, which depends on it.
    @Query(
            value = "select exists(select 1 from group_member where participant_id = :participantId)"
                    + " or exists(select 1 from team_member where participant_id = :participantId)",
            nativeQuery = true)
    boolean isInAGroupOrTeam(UUID participantId);
}
