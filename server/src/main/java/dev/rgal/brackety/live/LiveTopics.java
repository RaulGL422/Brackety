package dev.rgal.brackety.live;

import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.grouping.FightGroupRepository;
import dev.rgal.brackety.grouping.Match;
import dev.rgal.brackety.grouping.MatchRepository;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * What a client can follow (docs/modulos/tiempo-real.md): {@code event:<id>} (anything of the event: mats,
 * standings), {@code mat:<id>} (a mat's board, which changes with any match of the event: a fighter busy on
 * another mat) and {@code match:<id>} (one scoreboard). Only staff of the event follow any of them.
 */
@Component
public class LiveTopics {

    private static final String EVENT = "event:";
    private static final String MAT = "mat:";
    private static final String MATCH = "match:";

    private final MatchRepository matches;
    private final MatRepository mats;
    private final FightGroupRepository groups;
    private final EventAccess access;

    LiveTopics(MatchRepository matches, MatRepository mats, FightGroupRepository groups, EventAccess access) {
        this.matches = matches;
        this.mats = mats;
        this.groups = groups;
        this.access = access;
    }

    public static String event(UUID eventId) {
        return EVENT + eventId;
    }

    public static String mat(UUID matId) {
        return MAT + matId;
    }

    public static String match(UUID matchId) {
        return MATCH + matchId;
    }

    /** The topics a write to a path with these variables may change; empty when it says nothing of an event. */
    Set<String> changedBy(Map<String, String> pathVariables) {
        var topics = new LinkedHashSet<String>();
        uuid(pathVariables.get("eventId")).ifPresent(id -> topics.add(event(id)));
        uuid(pathVariables.get("matchId")).flatMap(matches::findById).ifPresent(match -> {
            topics.add(match(match.getId()));
            topics.add(event(match.getEventId()));
        });
        uuid(pathVariables.get("groupId"))
                .flatMap(groups::findById)
                .ifPresent(group -> topics.add(event(group.getEventId())));
        return topics;
    }

    /**
     * The published topic that {@code topic} follows ({@code mat:} follows its event) if the account is on the
     * event's staff; empty otherwise, or if it does not exist.
     */
    Optional<String> source(UUID accountId, String topic) {
        if (topic.startsWith(EVENT)) {
            return uuid(topic.substring(EVENT.length()))
                    .filter(eventId -> isStaff(eventId, accountId))
                    .map(LiveTopics::event);
        }
        if (topic.startsWith(MAT)) {
            return uuid(topic.substring(MAT.length()))
                    .flatMap(mats::findById)
                    .map(mat -> mat.getEventId())
                    .filter(eventId -> isStaff(eventId, accountId))
                    .map(LiveTopics::event);
        }
        if (topic.startsWith(MATCH)) {
            return uuid(topic.substring(MATCH.length()))
                    .flatMap(matches::findById)
                    .filter(match -> isStaff(match.getEventId(), accountId))
                    .map(Match::getId)
                    .map(LiveTopics::match);
        }
        return Optional.empty();
    }

    private boolean isStaff(UUID eventId, UUID accountId) {
        return !access.roles(eventId, accountId).isEmpty();
    }

    private static Optional<UUID> uuid(String value) {
        if (value == null) {
            return Optional.empty();
        }
        try {
            return Optional.of(UUID.fromString(value));
        } catch (IllegalArgumentException e) {
            return Optional.empty();
        }
    }
}
