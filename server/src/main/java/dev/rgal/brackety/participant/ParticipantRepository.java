package dev.rgal.brackety.participant;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ParticipantRepository extends JpaRepository<Participant, UUID> {

    @Query("select p from Participant p join fetch p.person pe where p.eventId = :eventId"
            + " order by pe.firstName, pe.lastName")
    List<Participant> findByEventIdOrderByFirstNameAscLastNameAsc(UUID eventId);

    List<Participant> findByEventIdIn(Collection<UUID> eventIds);

    boolean existsByPerson_Id(UUID personId);

    // Native so this package does not depend on grouping, which depends on it.
    @Query(
            value = "select exists(select 1 from group_member where participant_id = :participantId)"
                    + " or exists(select 1 from team_member where participant_id = :participantId)",
            nativeQuery = true)
    boolean isInAGroupOrTeam(UUID participantId);

    /** In a group or team of any event: their birth date set a category there. */
    @Query(
            value = "select exists(select 1 from group_member g join participant p on p.id = g.participant_id"
                    + " where p.person_id = :personId)"
                    + " or exists(select 1 from team_member t join participant p on p.id = t.participant_id"
                    + " where p.person_id = :personId)",
            nativeQuery = true)
    boolean isPersonInAGroupOrTeam(UUID personId);
}
