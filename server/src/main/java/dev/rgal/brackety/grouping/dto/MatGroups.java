package dev.rgal.brackety.grouping.dto;

import java.util.List;
import java.util.UUID;

/**
 * One mat and its groups still to finish, for seeing and moving them at a glance (GR-4). {@code disabled}: it takes no
 * groups. {@code finishedGroups}: how many are done there (they are not listed).
 */
public record MatGroups(
        UUID matId, int number, String referee, boolean disabled, int finishedGroups, List<GroupCard> groups) {

    /**
     * {@code played} of {@code matches} finished; {@code inProgress}: one is on now, so it cannot move.
     * {@code members}: in group order, wildcards marked.
     */
    public record GroupCard(
            UUID id,
            int number,
            String categoryName,
            List<Member> members,
            int played,
            int matches,
            boolean inProgress) {}

    public record Member(String name, boolean ghost) {}
}
