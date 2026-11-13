package dev.rgal.brackety.grouping;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.grouping.MatchDispatch.MatView;
import dev.rgal.brackety.grouping.MatchRecommender.Candidate;
import dev.rgal.brackety.grouping.MatchRecommender.Context;
import dev.rgal.brackety.grouping.dto.MatBoardResponse.Corner;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/** Every mat and the team pool of an event right now, with what each idle mat should start (MatchDispatch). */
@Component
class MatFloor {

    /** Why a pending match cannot start now. */
    enum Wait {
        REVIEW,
        BUSY,
        RESTING,
        OTHER_MAT
    }

    record Floor(
            List<Mat> mats,
            List<Match> matches,
            Map<UUID, FightGroup> groups,
            Competitors competitors,
            Context context,
            Map<UUID, MatView> views,
            Map<UUID, Candidate> proposals) {

        /** The mat takes team matches from the pool: no individual match is pending on it. */
        boolean takesPool(UUID matId) {
            return views.get(matId).individual().isEmpty();
        }

        boolean running(UUID matId) {
            return views.get(matId).running();
        }

        /** Null if it can start now. */
        Wait waitOf(Match m, UUID matId) {
            if (m.isInReview()) {
                return Wait.REVIEW;
            }
            var c = candidate(m);
            if (!context.isFree(c)) {
                return Wait.BUSY;
            }
            if (!context.isReady(c)) {
                return Wait.RESTING;
            }
            return proposedTo(m).filter(other -> !other.equals(matId)).isPresent() ? Wait.OTHER_MAT : null;
        }

        Instant readyAt(Match m) {
            return context.readyAt(candidate(m));
        }

        Optional<UUID> proposedTo(Match m) {
            return proposals.entrySet().stream()
                    .filter(e -> e.getValue().matchId().equals(m.getId()))
                    .map(Map.Entry::getKey)
                    .findFirst();
        }

        Integer matNumber(UUID matId) {
            return mats.stream()
                    .filter(x -> x.getId().equals(matId))
                    .map(Mat::getNumber)
                    .findFirst()
                    .orElse(null);
        }

        Candidate candidate(Match m) {
            return MatFloor.candidate(m, groups.get(m.getGroupId()));
        }

        /** For one corner of a pending match: see {@link Corner}. */
        Corner corner(Match m, UUID fighterId, Event event) {
            var people = competitors.participants(fighterId);
            Integer fightingOn = null;
            var freeAt = context.readyAt(new Candidate(m.getId(), null, 0, 0, fighterId, fighterId));
            var pendingMats = new ArrayList<Integer>();
            for (var other : matches) {
                if (other.getId().equals(m.getId())
                        || Collections.disjoint(
                                people, competitors.participants(other.getRedId(), other.getBlueId()))) {
                    continue;
                }
                if (other.getStatus() == Match.Status.IN_PROGRESS) {
                    fightingOn = matNumber(other.getMatId());
                    var end = other.getStartedAt()
                            .plusSeconds(event.matchSecondsFor(other.isTeamMatch()))
                            .plus(context.minRest());
                    freeAt = later(freeAt, end);
                } else if (other.getStatus() == Match.Status.PENDING && other.getMatId() != null) {
                    pendingMats.add(matNumber(other.getMatId()));
                }
            }
            pendingMats.sort(Comparator.naturalOrder());
            return new Corner(fightingOn, freeAt.isAfter(context.now()) ? freeAt : null, pendingMats);
        }
    }

    private final MatRepository mats;
    private final FightGroupRepository groups;
    private final MatchRepository matches;
    private final CompetitorDirectory directory;

    MatFloor(MatRepository mats, FightGroupRepository groups, MatchRepository matches, CompetitorDirectory directory) {
        this.mats = mats;
        this.groups = groups;
        this.matches = matches;
        this.directory = directory;
    }

    Floor load(Event event, Instant now) {
        var eventMats = mats.findByEventIdOrderByNumber(event.getId());
        var eventMatches = matches.findByEventId(event.getId());
        var groupById = groups.findByEventId(event.getId()).stream()
                .collect(Collectors.toMap(FightGroup::getId, Function.identity()));
        var competitors = directory.of(event.getId());

        var busy = new HashSet<UUID>();
        var lastFought = new HashMap<UUID, Instant>();
        var groupLastPlayed = new HashMap<UUID, Instant>();
        for (var m : eventMatches) {
            var people = competitors.participants(m.getRedId(), m.getBlueId());
            if (m.getStatus() == Match.Status.IN_PROGRESS) {
                busy.addAll(people);
            }
            if (m.getFinishedAt() != null) {
                people.forEach(p -> lastFought.merge(p, m.getFinishedAt(), MatFloor::later));
                groupLastPlayed.merge(m.getGroupId(), m.getFinishedAt(), MatFloor::later);
            }
        }
        var context = new Context(
                now,
                slot(event, false),
                lastFought,
                groupById.values().stream().collect(Collectors.toMap(FightGroup::getId, FightGroup::getCreatedAt)),
                groupLastPlayed,
                busy,
                Set.of(),
                competitors.teamMembers(),
                Duration.ofSeconds(event.getMinRestSeconds()),
                eventMatches.stream()
                        .filter(Match::isRestWaived)
                        .map(Match::getId)
                        .collect(Collectors.toSet()));

        var views = new HashMap<UUID, MatView>();
        for (var mat : eventMats) {
            var onMat = eventMatches.stream()
                    .filter(m -> mat.getId().equals(m.getMatId()))
                    .toList();
            var last = onMat.stream()
                    .filter(m -> m.getFinishedAt() != null)
                    .max(Comparator.comparing(Match::getFinishedAt));
            views.put(
                    mat.getId(),
                    new MatView(
                            mat.getId(),
                            mat.getNumber(),
                            mat.getRefereeAccountId() != null,
                            onMat.stream().anyMatch(m -> m.getStatus() == Match.Status.IN_PROGRESS),
                            last.map(Match::getFinishedAt).orElse(null),
                            last.map(m -> competitors.participants(m.getRedId(), m.getBlueId()))
                                    .orElse(Set.of()),
                            onMat.stream()
                                    .filter(m -> m.getStatus() == Match.Status.PENDING && !m.isInReview())
                                    .map(m -> candidate(m, groupById.get(m.getGroupId())))
                                    .toList()));
        }
        var pool = eventMatches.stream()
                .filter(m -> m.getMatId() == null && m.getStatus() == Match.Status.PENDING && !m.isInReview())
                .map(m -> candidate(m, groupById.get(m.getGroupId())))
                .toList();
        var proposals = MatchDispatch.recommend(
                eventMats.stream().map(m -> views.get(m.getId())).toList(),
                pool,
                context,
                slot(event, false),
                slot(event, true));
        return new Floor(eventMats, eventMatches, groupById, competitors, context, views, proposals);
    }

    static Duration slot(Event event, boolean teams) {
        return Duration.ofSeconds(event.matchSecondsFor(teams) + event.getChangeoverSeconds());
    }

    static Candidate candidate(Match m, FightGroup group) {
        return new Candidate(
                m.getId(), m.getGroupId(), group.getNumber(), m.getOrderIndex(), m.getRedId(), m.getBlueId());
    }

    private static Instant later(Instant a, Instant b) {
        return a.isAfter(b) ? a : b;
    }
}
