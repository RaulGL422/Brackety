package dev.rgal.brackety.grouping;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.util.UUID;

/**
 * A participant or a team in a group. A ghost fights the group's matches but scores nothing in
 * them; their opponents do.
 */
@Entity
public class GroupMember {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID groupId;
    private UUID participantId;
    private UUID teamId;
    private int position;
    private boolean ghost;

    protected GroupMember() {}

    GroupMember(UUID groupId, UUID competitorId, boolean team, int position, boolean ghost) {
        this.groupId = groupId;
        this.participantId = team ? null : competitorId;
        this.teamId = team ? competitorId : null;
        this.position = position;
        this.ghost = ghost;
    }

    public UUID getGroupId() {
        return groupId;
    }

    public UUID getParticipantId() {
        return participantId;
    }

    public UUID getTeamId() {
        return teamId;
    }

    /** The participant's or the team's id. */
    public UUID getCompetitorId() {
        return teamId != null ? teamId : participantId;
    }

    public int getPosition() {
        return position;
    }

    public boolean isGhost() {
        return ghost;
    }
}
