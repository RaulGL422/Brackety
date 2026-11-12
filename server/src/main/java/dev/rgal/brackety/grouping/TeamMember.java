package dev.rgal.brackety.grouping;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.util.UUID;

@Entity
public class TeamMember {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID teamId;
    private UUID participantId;
    private int position;
    private boolean ghost;

    protected TeamMember() {}

    /** {@code ghost}: fills a real team in without scoring for it; every member of a ghost team is one. */
    TeamMember(Team team, UUID participantId, int position, boolean ghost) {
        this.teamId = team.getId();
        this.participantId = participantId;
        this.position = position;
        this.ghost = team.isGhost() || ghost;
    }

    public UUID getTeamId() {
        return teamId;
    }

    public UUID getParticipantId() {
        return participantId;
    }

    public int getPosition() {
        return position;
    }

    public boolean isGhost() {
        return ghost;
    }
}
