package dev.rgal.brackety.grouping;

import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.grouping.MatchRecommender.Candidate;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * The order in which each mat's referee would be offered the pending matches if everything goes as planned: every
 * match lasts its full time plus the changeover and the referees always start the recommended one. All mats run at
 * once, so a fighter busy on one mat (a ghost, say) holds back another, as on the day. Matches in review wait for the
 * club and are left out.
 */
@Component
public class MatPlanner {

    /** {@code startsAt}: when it would start, from now. */
    public record Planned(UUID matchId, Instant startsAt) {}

    private record Running(UUID matId, UUID groupId, Set<UUID> fighters, Instant end) {}

    private final MatRepository mats;
    private final FightGroupRepository groups;
    private final MatchRepository matches;
    private final CompetitorDirectory directory;
    private final EventService events;
    private final Clock clock;

    MatPlanner(
            MatRepository mats,
            FightGroupRepository groups,
            MatchRepository matches,
            CompetitorDirectory directory,
            EventService events,
            Clock clock) {
        this.mats = mats;
        this.groups = groups;
        this.matches = matches;
        this.directory = directory;
        this.events = events;
        this.clock = clock;
    }

    /** Per mat id, its pending matches in the order they would come up. */
    @Transactional(readOnly = true)
    public Map<UUID, List<Planned>> plan(UUID eventId) {
        var event = events.get(eventId);
        var now = clock.instant();
        var length = Duration.ofSeconds(event.getMatchSeconds());
        var changeover = Duration.ofSeconds(event.getChangeoverSeconds());
        var competitors = directory.of(eventId);
        var groupById = groups.findByEventId(eventId).stream()
                .collect(Collectors.toMap(FightGroup::getId, Function.identity()));

        var lastFought = new HashMap<UUID, Instant>();
        var groupLastPlayed = new HashMap<UUID, Instant>();
        var justFought = new HashMap<UUID, Set<UUID>>();
        var lastOnMat = new HashMap<UUID, Instant>();
        var running = new ArrayList<Running>();
        var freeAt = new HashMap<UUID, Instant>();
        var pending = new LinkedHashMap<UUID, List<Candidate>>();
        var plan = new LinkedHashMap<UUID, List<Planned>>();
        for (var mat : mats.findByEventIdOrderByNumber(eventId)) {
            freeAt.put(mat.getId(), now);
            pending.put(mat.getId(), new ArrayList<>());
            plan.put(mat.getId(), new ArrayList<>());
        }
        for (var m : matches.findByEventId(eventId)) {
            var fighters = competitors.participants(m.getRedId(), m.getBlueId());
            if (m.getFinishedAt() != null) {
                finished(
                        m.getMatId(),
                        m.getGroupId(),
                        fighters,
                        m.getFinishedAt(),
                        lastFought,
                        groupLastPlayed,
                        justFought,
                        lastOnMat);
            }
            if (m.getStatus() == Match.Status.IN_PROGRESS) {
                var end = now.plus(m.clockLeft(now, length));
                running.add(new Running(m.getMatId(), m.getGroupId(), fighters, end));
                freeAt.put(m.getMatId(), end.plus(changeover));
            } else if (m.getStatus() == Match.Status.PENDING && !m.isInReview()) {
                var group = groupById.get(m.getGroupId());
                pending.get(m.getMatId())
                        .add(new Candidate(
                                m.getId(),
                                m.getGroupId(),
                                group.getNumber(),
                                m.getOrderIndex(),
                                m.getRedId(),
                                m.getBlueId()));
            }
        }
        var groupCreated =
                groupById.values().stream().collect(Collectors.toMap(FightGroup::getId, FightGroup::getCreatedAt));
        var slot = length.plus(changeover);

        while (true) {
            var next = pending.entrySet().stream()
                    .filter(e -> !e.getValue().isEmpty())
                    .map(Map.Entry::getKey)
                    .min(Comparator.comparing(freeAt::get));
            if (next.isEmpty()) {
                break;
            }
            var matId = next.get();
            var at = freeAt.get(matId);
            var done = running.stream().filter(r -> !r.end().isAfter(at)).toList();
            for (var r : done) {
                finished(
                        r.matId(),
                        r.groupId(),
                        r.fighters(),
                        r.end(),
                        lastFought,
                        groupLastPlayed,
                        justFought,
                        lastOnMat);
            }
            running.removeAll(done);
            var busy = new HashSet<UUID>();
            running.forEach(r -> busy.addAll(r.fighters()));
            var context = new MatchRecommender.Context(
                    at,
                    slot,
                    lastFought,
                    groupCreated,
                    groupLastPlayed,
                    busy,
                    justFought.getOrDefault(matId, Set.of()),
                    competitors.teamMembers());
            var candidates = pending.get(matId);
            var pick = MatchRecommender.recommend(candidates, context);
            if (pick.isEmpty()) {
                // Everyone left here is fighting elsewhere: this mat waits for the first of those to end.
                var wait = running.stream().map(Running::end).min(Comparator.naturalOrder());
                if (wait.isEmpty()) {
                    break;
                }
                freeAt.put(matId, wait.get());
                continue;
            }
            var chosen = candidates.stream()
                    .filter(c -> c.matchId().equals(pick.get()))
                    .findFirst()
                    .orElseThrow();
            candidates.remove(chosen);
            plan.get(matId).add(new Planned(chosen.matchId(), at));
            running.add(new Running(
                    matId, chosen.groupId(), competitors.participants(chosen.red(), chosen.blue()), at.plus(length)));
            freeAt.put(matId, at.plus(slot));
        }
        return plan;
    }

    // The recommender's view after a match: when its fighters last fought, when its group last played on the mat,
    // and who has just fought there.
    private static void finished(
            UUID matId,
            UUID groupId,
            Set<UUID> fighters,
            Instant end,
            Map<UUID, Instant> lastFought,
            Map<UUID, Instant> groupLastPlayed,
            Map<UUID, Set<UUID>> justFought,
            Map<UUID, Instant> lastOnMat) {
        fighters.forEach(p -> lastFought.merge(p, end, MatPlanner::later));
        groupLastPlayed.merge(groupId, end, MatPlanner::later);
        if (!lastOnMat.containsKey(matId) || end.isAfter(lastOnMat.get(matId))) {
            lastOnMat.put(matId, end);
            justFought.put(matId, fighters);
        }
    }

    private static Instant later(Instant a, Instant b) {
        return a.isAfter(b) ? a : b;
    }
}
