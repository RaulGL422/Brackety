package dev.rgal.brackety.grouping;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/** Every participant and team of an event by id. */
public final class Competitors {

    private final Map<UUID, Competitor> byId;

    Competitors(Map<UUID, Competitor> byId) {
        this.byId = byId;
    }

    public Competitor get(UUID id) {
        return byId.get(id);
    }

    public String name(UUID id) {
        return id == null ? null : byId.get(id).name();
    }

    /** The participants behind each competitor: one for a participant, the members for a team. */
    public Set<UUID> participants(UUID... ids) {
        var result = new HashSet<UUID>();
        for (var id : ids) {
            result.addAll(byId.get(id).participantIds());
        }
        return result;
    }

    /** Those who score for each competitor: the participant, or a team's real members. */
    public Set<UUID> scorers(UUID... ids) {
        var result = new HashSet<UUID>();
        for (var id : ids) {
            result.addAll(byId.get(id).scorerIds());
        }
        return result;
    }

    Map<UUID, Set<UUID>> teamMembers() {
        var result = new HashMap<UUID, Set<UUID>>();
        byId.values().stream()
                .filter(Competitor::isTeam)
                .forEach(c -> result.put(c.id(), Set.copyOf(c.participantIds())));
        return result;
    }
}
