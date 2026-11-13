package dev.rgal.brackety.grouping;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface TeamMemberRepository extends JpaRepository<TeamMember, UUID> {

    List<TeamMember> findByParticipantIdInAndGhostFalse(Collection<UUID> participantIds);

    List<TeamMember> findByTeamIdIn(Collection<UUID> teamIds);

    @Query("select m from TeamMember m where m.teamId in (select t.id from Team t where t.eventId = :eventId)"
            + " order by m.position")
    List<TeamMember> findByEventId(UUID eventId);
}
