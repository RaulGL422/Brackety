package dev.rgal.brackety.grouping;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface GroupMemberRepository extends JpaRepository<GroupMember, UUID> {

    List<GroupMember> findByGroupIdInOrderByPosition(Collection<UUID> groupIds);

    List<GroupMember> findByParticipantIdInAndGhostFalse(Collection<UUID> participantIds);

    List<GroupMember> findByTeamIdIn(Collection<UUID> teamIds);

    @Query("select m from GroupMember m where m.groupId in (select g.id from FightGroup g where g.eventId = :eventId)")
    List<GroupMember> findByEventId(UUID eventId);
}
