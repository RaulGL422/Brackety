package dev.rgal.brackety.grouping;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.grouping.MatchDispatch.MatView;
import dev.rgal.brackety.grouping.MatchRecommender.Candidate;
import dev.rgal.brackety.grouping.MatchRecommender.Context;
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
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * The order in which each mat's referee would be offered the pending matches if everything goes as planned: every
 * match lasts its full time plus the changeover and the referees always start the proposed one (MatchDispatch). All
 * mats run at once, so a fighter busy or resting on one mat holds back another, and team matches go to whichever mat
 * is free of individual matches. Matches in review wait for the club and are left out.
 */
@Component
public class MatPlanner {

    /** {@code startsAt}: when it would start, from now. */
    public record Planned(UUID matchId, Instant startsAt) {}

    private record Running(UUID matId, UUID groupId, Set<UUID> people, Instant end) {}

    private final MatFloor floor;
    private final EventService events;
    private final Clock clock;

    MatPlanner(MatFloor floor, EventService events, Clock clock) {
        this.floor = floor;
        this.events = events;
        this.clock = clock;
    }

    /** Per mat id, its pending matches in the order they would come up (team matches on the mat that takes them). */
    @Transactional(readOnly = true)
    public Map<UUID, List<Planned>> plan(UUID eventId) {
        var event = events.get(eventId);
        var now = clock.instant();
        return simulate(event, floor.load(event, now), now);
    }

    static Map<UUID, List<Planned>> simulate(Event event, MatFloor.Floor floor, Instant now) {
        var competitors = floor.competitors();
        var changeover = Duration.ofSeconds(event.getChangeoverSeconds());
        var start = floor.context();
        var lastFought = new HashMap<>(start.lastFought());
        var groupLastPlayed = new HashMap<>(start.groupLastPlayed());
        var justFought = new HashMap<UUID, Set<UUID>>();
        var lastFinished = new HashMap<UUID, Instant>();
        var freeAt = new HashMap<UUID, Instant>();
        var individual = new HashMap<UUID, List<Candidate>>();
        var plan = new LinkedHashMap<UUID, List<Planned>>();
        var running = new ArrayList<Running>();
        for (var mat : floor.mats()) {
            var view = floor.views().get(mat.getId());
            justFought.put(mat.getId(), view.justFought());
            if (view.lastFinished() != null) {
                lastFinished.put(mat.getId(), view.lastFinished());
            }
            freeAt.put(mat.getId(), now);
            individual.put(mat.getId(), new ArrayList<>(view.individual()));
            plan.put(mat.getId(), new ArrayList<>());
        }
        var pool = new ArrayList<Candidate>();
        for (var m : floor.matches()) {
            if (m.getStatus() == Match.Status.IN_PROGRESS) {
                var length = Duration.ofSeconds(event.matchSecondsFor(m.isTeamMatch()));
                // Over its time but not finished: its mat is still busy now, as the dispatch sees it (with no
                // changeover, ending it "now" gave its mat a match while another mat was told to start that one).
                var end = later(now.plus(m.clockLeft(now, length)), now.plusMillis(1));
                running.add(new Running(
                        m.getMatId(), m.getGroupId(), competitors.participants(m.getRedId(), m.getBlueId()), end));
                freeAt.put(m.getMatId(), end.plus(changeover));
            } else if (m.getMatId() == null && m.getStatus() == Match.Status.PENDING && !m.isInReview()) {
                pool.add(floor.candidate(m));
            }
        }
        var teamMatches = pool.stream().map(Candidate::matchId).collect(Collectors.toSet());

        while (true) {
            var withWork = floor.mats().stream()
                    .map(Mat::getId)
                    .filter(id -> freeAt.get(id) != Instant.MAX)
                    .filter(id -> !individual.get(id).isEmpty()
                            || (floor.views().get(id).hasReferee() && !pool.isEmpty()))
                    .toList();
            if (withWork.isEmpty()) {
                break;
            }
            var at = withWork.stream()
                    .map(freeAt::get)
                    .min(Comparator.naturalOrder())
                    .orElseThrow();
            for (var r : running.stream().filter(r -> !r.end().isAfter(at)).toList()) {
                r.people().forEach(p -> lastFought.merge(p, r.end(), MatPlanner::later));
                groupLastPlayed.merge(r.groupId(), r.end(), MatPlanner::later);
                if (!lastFinished.containsKey(r.matId()) || r.end().isAfter(lastFinished.get(r.matId()))) {
                    lastFinished.put(r.matId(), r.end());
                    justFought.put(r.matId(), r.people());
                }
                running.remove(r);
            }
            var busy = new HashSet<UUID>();
            running.forEach(r -> busy.addAll(r.people()));
            var context = new Context(
                    at,
                    start.slot(),
                    lastFought,
                    start.groupCreated(),
                    groupLastPlayed,
                    busy,
                    Set.of(),
                    start.teamMembers(),
                    start.minRest(),
                    start.restWaived());
            var views = floor.mats().stream()
                    .map(mat -> new MatView(
                            mat.getId(),
                            mat.getNumber(),
                            mat.getRefereeAccountId() != null,
                            freeAt.get(mat.getId()).isAfter(at),
                            lastFinished.get(mat.getId()),
                            justFought.get(mat.getId()),
                            individual.get(mat.getId())))
                    .toList();
            var picks = MatchDispatch.recommend(
                    views, pool, context, MatFloor.slot(event, false), MatFloor.slot(event, true));
            var idle =
                    withWork.stream().filter(id -> !freeAt.get(id).isAfter(at)).toList();
            for (var matId : idle.stream().filter(picks::containsKey).toList()) {
                var pick = picks.get(matId);
                individual.get(matId).remove(pick);
                pool.remove(pick);
                plan.get(matId).add(new Planned(pick.matchId(), at));
                var length = Duration.ofSeconds(event.matchSecondsFor(teamMatches.contains(pick.matchId())));
                running.add(new Running(matId, pick.groupId(), context.people(pick), at.plus(length)));
                freeAt.put(matId, at.plus(length).plus(changeover));
            }
            // Everyone left for a mat is fighting or resting: it waits for the first of them.
            for (var matId : idle.stream().filter(id -> !picks.containsKey(id)).toList()) {
                var candidates = individual.get(matId).isEmpty() ? pool : individual.get(matId);
                freeAt.put(matId, wakeUp(at, running, candidates, context));
            }
        }
        return plan;
    }

    // The first moment something changes for a waiting mat: a match ends or a fighter has rested; never if neither.
    private static Instant wakeUp(Instant at, List<Running> running, List<Candidate> candidates, Context context) {
        var ends = running.stream().map(Running::end).filter(e -> e.isAfter(at));
        var rested = candidates.stream().map(context::readyAt).filter(r -> r.isAfter(at));
        return Stream.concat(ends, rested).min(Comparator.naturalOrder()).orElse(Instant.MAX);
    }

    private static Instant later(Instant a, Instant b) {
        return a.isAfter(b) ? a : b;
    }
}
