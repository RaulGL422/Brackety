package dev.rgal.brackety.scoreboard;

import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.grouping.Competitor;
import dev.rgal.brackety.grouping.CompetitorDirectory;
import dev.rgal.brackety.grouping.FightGroupRepository;
import dev.rgal.brackety.grouping.GroupMember;
import dev.rgal.brackety.grouping.GroupMemberRepository;
import dev.rgal.brackety.grouping.Match;
import dev.rgal.brackety.grouping.MatchRepository;
import dev.rgal.brackety.scoreboard.RejectedOp.Cause;
import dev.rgal.brackety.scoreboard.dto.MatchEventRequest;
import dev.rgal.brackety.scoreboard.dto.MatchView;
import dev.rgal.brackety.scoreboard.dto.MatchView.Corner;
import dev.rgal.brackety.scoreboard.dto.MatchView.Review;
import dev.rgal.brackety.scoreboard.dto.MatchView.ReviewOp;
import dev.rgal.brackety.scoreboard.dto.MatchView.TimelineEntry;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class ScoreboardService {

    static final String MATCH_CONFLICT = "MATCH_CONFLICT";
    static final String MATCH_IN_REVIEW = "MATCH_IN_REVIEW";
    static final String MATCH_STALE = "MATCH_STALE";
    static final String FIGHTER_RESTING = "FIGHTER_RESTING";

    private static final Logger log = LoggerFactory.getLogger(ScoreboardService.class);

    private static final Set<MatchEventType> NEED_SIDE = EnumSet.of(
            MatchEventType.POINT,
            MatchEventType.POINT_REMOVED,
            MatchEventType.WARNING,
            MatchEventType.ONE_HAND_WARNING,
            MatchEventType.DISQUALIFICATION);
    private static final Set<MatchEventType> NEED_REASON = EnumSet.of(
            MatchEventType.WARNING,
            MatchEventType.ONE_HAND_WARNING,
            MatchEventType.DISQUALIFICATION,
            MatchEventType.CANCEL,
            MatchEventType.REOPEN);

    /** {@code conflictCode}: null when the action is applied (now or before), else the code of the 409. */
    record Recorded(MatchView view, String conflictCode) {}

    private final MatchRepository matches;
    private final MatchEventRepository matchEvents;
    private final RejectedOpRepository rejectedOps;
    private final MatRepository mats;
    private final FightGroupRepository groups;
    private final GroupMemberRepository members;
    private final CompetitorDirectory directory;
    private final AccountRepository accounts;
    private final EventService events;
    private final EventAccess access;
    private final MatchWriter writer;
    private final Clock clock;

    ScoreboardService(
            MatchRepository matches,
            MatchEventRepository matchEvents,
            RejectedOpRepository rejectedOps,
            MatRepository mats,
            FightGroupRepository groups,
            GroupMemberRepository members,
            CompetitorDirectory directory,
            AccountRepository accounts,
            EventService events,
            EventAccess access,
            MatchWriter writer,
            Clock clock) {
        this.matches = matches;
        this.matchEvents = matchEvents;
        this.rejectedOps = rejectedOps;
        this.mats = mats;
        this.groups = groups;
        this.members = members;
        this.directory = directory;
        this.accounts = accounts;
        this.events = events;
        this.access = access;
        this.writer = writer;
        this.clock = clock;
    }

    /** The 409 of an offline action: the same on the first try and on every retry. */
    static EventException offlineConflict(String code) {
        return EventException.conflict(
                code,
                MATCH_CONFLICT.equals(code)
                        ? "The match clashed with another device: the club has to review it."
                        : "The match is waiting for the club's review.");
    }

    /** For the mat's referee and the club (who follows the timeline). */
    @Transactional(readOnly = true)
    MatchView view(UUID matchId, UUID accountId) {
        var match = matches.findById(matchId).orElseThrow(EventException::notFound);
        var roles = access.roles(match.getEventId(), accountId);
        if (roles.isEmpty()) {
            throw EventException.notFound();
        }
        // A team match in the pool can go to any mat: every referee may open it.
        var mat = matOrNull(match);
        var allowed = roles.contains(EventRole.CLUB)
                || (mat == null ? roles.contains(EventRole.REFEREE) : isReferee(mat, accountId, roles));
        if (!allowed) {
            throw EventException.forbidden();
        }
        return view(match, mat, events.get(match.getEventId()), clock.instant());
    }

    /**
     * Only the referee of the mat writes its matches. An action with {@code opId} (docs/modulos/offline.md)
     * is applied once and at its own time; if it clashes, it is kept for the club's review instead.
     */
    @Transactional
    Recorded record(UUID matchId, UUID accountId, MatchEventRequest request) {
        var match = matches.lockById(matchId).orElseThrow(EventException::notFound);
        var roles = access.roles(match.getEventId(), accountId);
        if (roles.isEmpty()) {
            throw EventException.notFound();
        }
        var mat = match.getMatId() == null ? refereeMatOf(match, accountId).orElse(null) : mat(match);
        if (mat == null || !isReferee(mat, accountId, roles)) {
            throw EventException.forbidden();
        }
        return apply(match, mat, accountId, request);
    }

    /** The mat a team match from the pool goes to: the one of the referee who starts it. */
    Optional<Mat> refereeMatOf(Match match, UUID accountId) {
        return mats.findByEventIdAndRefereeAccountIdOrderByNumber(match.getEventId(), accountId).stream()
                .findFirst();
    }

    /**
     * An action rescued from a device's CSV (OfflineImportService): the club already checked, {@code actorId} is
     * the referee who made it. Same path as the queue, so a known {@code opId} changes nothing.
     */
    @Transactional
    Recorded recordImported(UUID matchId, UUID actorId, MatchEventRequest request) {
        var match = matches.lockById(matchId).orElseThrow(EventException::notFound);
        var mat = match.getMatId() == null
                ? refereeMatOf(match, actorId)
                        .orElseThrow(() -> EventException.conflict("The referee of this action has no mat now."))
                : mat(match);
        return apply(match, mat, actorId, request);
    }

    private Recorded apply(Match match, Mat mat, UUID accountId, MatchEventRequest request) {
        var event = events.get(mat.getEventId());
        var action = action(request, accountId);
        var serverNow = clock.instant();
        // A pool match is on this mat while it runs; refused or cancelled, it goes back to the pool.
        match.takeMat(mat.getId());
        var conflict = request.opId() == null
                ? recordOnline(match, event, action, request.knownEvents(), serverNow)
                : recordOffline(match, event, action, request, serverNow);
        match.backToPoolIf(groups.findById(match.getGroupId()).orElseThrow());
        return new Recorded(conflict == null ? view(match, mat, event, serverNow) : null, conflict);
    }

    private static MatchWriter.Action action(MatchEventRequest request, UUID accountId) {
        var type = request.type();
        var side = NEED_SIDE.contains(type) ? request.side() : null;
        var reason = request.reason() == null ? "" : request.reason().strip();
        if (NEED_SIDE.contains(type) && side == null) {
            throw EventException.invalid("Say which fighter.");
        }
        if (NEED_REASON.contains(type) && reason.isEmpty()) {
            throw EventException.invalid("A warning or disqualification needs a reason.");
        }
        var adjust = type == MatchEventType.CLOCK_ADJUST;
        if (adjust && (request.deltaMs() == null || request.deltaMs() == 0)) {
            throw EventException.invalid("A clock adjustment needs deltaMs.");
        }
        // Two tabs pressing at once would otherwise both count: every action says what it saw.
        if (request.knownEvents() == null) {
            throw EventException.invalid("Every action needs knownEvents.");
        }
        return new MatchWriter.Action(
                type,
                side,
                NEED_REASON.contains(type) ? reason : null,
                adjust ? request.deltaMs() : null,
                request.opId(),
                accountId);
    }

    // Online the referee sees the clash at once: refused, not sent to the club's review.
    private String recordOnline(Match match, Event event, MatchWriter.Action action, int knownEvents, Instant now) {
        if (match.isInReview()) {
            throw offlineConflict(MATCH_IN_REVIEW);
        }
        var history = new ArrayList<>(matchEvents.findByMatchIdOrderByPosition(match.getId()));
        if (knownEvents != MatchWriter.knownEvents(history)) {
            throw EventException.conflict(
                    MATCH_STALE, "The match changed on another device: check the scoreboard and try again.");
        }
        writer.append(match, event, history, action, now, true, true).ifPresent(refusal -> {
            throw switch (refusal.cause()) {
                case AGE -> EventException.invalid(refusal.detail());
                case FIGHTER_RESTING -> EventException.conflict(FIGHTER_RESTING, refusal.detail());
                default -> EventException.conflict(refusal.detail());
            };
        });
        return null;
    }

    private String recordOffline(
            Match match, Event event, MatchWriter.Action action, MatchEventRequest request, Instant serverNow) {
        // A retry gets the first answer, even if the club has applied the action since.
        var earlier = rejectedOps.findByOpId(action.opId());
        if (earlier.isPresent()) {
            return code(earlier.get().getCause());
        }
        if (matchEvents.existsByOpId(action.opId())) {
            return null;
        }
        var history = new ArrayList<>(matchEvents.findByMatchIdOrderByPosition(match.getId()));
        var now = MatchWriter.effectiveTime(history, request.at(), serverNow);
        if (match.isInReview()) {
            return reject(match, action, now, Cause.IN_REVIEW, serverNow);
        }
        if (request.knownEvents() != MatchWriter.knownEvents(history)) {
            return reject(match, action, now, Cause.KNOWN_EVENTS, serverNow);
        }
        return writer.append(match, event, history, action, now, true, false)
                .map(refusal -> reject(match, action, now, refusal.cause(), serverNow))
                .orElse(null);
    }

    // The first clash puts the match in review; from then on every device action waits for the club.
    private String reject(Match match, MatchWriter.Action action, Instant at, Cause cause, Instant serverNow) {
        var position = rejectedOps.countByMatchId(match.getId());
        rejectedOps.save(new RejectedOp(match.getId(), position, action, at, cause, serverNow));
        if (cause != Cause.IN_REVIEW) {
            match.putInReview(cause.name());
            log.info("Match {} put in review: {} on {}", match.getId(), cause, action.type());
        }
        return code(cause);
    }

    private static String code(Cause cause) {
        return cause == Cause.IN_REVIEW ? MATCH_IN_REVIEW : MATCH_CONFLICT;
    }

    MatchView view(Match match, Mat mat, Event event, Instant now) {
        var history = matchEvents.findByMatchIdOrderByPosition(match.getId());
        var state = MatchWriter.replay(event, match, history);
        var group = groups.findById(match.getGroupId()).orElseThrow();
        var competitors = directory.of(match.getEventId());
        var ghosts = members.findByGroupIdInOrderByPosition(List.of(group.getId())).stream()
                .filter(GroupMember::isGhost)
                .map(GroupMember::getCompetitorId)
                .collect(Collectors.toSet());
        var pending = match.isInReview()
                ? rejectedOps.findByMatchIdAndResolutionIsNullOrderByPosition(match.getId())
                : List.<RejectedOp>of();
        var actors = actors(Stream.concat(
                history.stream().map(MatchEvent::getActorAccountId),
                pending.stream().map(RejectedOp::getActorAccountId)));
        return new MatchView(
                match.getId(),
                mat == null ? null : mat.getId(),
                mat == null ? null : mat.getNumber(),
                group.getNumber(),
                match.getStatus(),
                event.matchSecondsFor(match.isTeamMatch()),
                event.pointsLimitFor(match.isTeamMatch()),
                state.remainingAt(now).toMillis(),
                state.isRunning(now),
                state.endReason(now).map(Enum::name).orElse(null),
                corner(event, state, Side.RED, competitors.get(match.getRedId()), ghosts),
                corner(event, state, Side.BLUE, competitors.get(match.getBlueId()), ghosts),
                timeline(history, state, actors),
                now,
                match.isInReview() ? review(match, pending, actors) : null,
                match.getStatus() == Match.Status.PENDING
                        ? writer.restedAt(match, event).filter(now::isBefore).orElse(null)
                        : null);
    }

    private Map<UUID, String> actors(Stream<UUID> ids) {
        return accounts.findAllById(ids.filter(Objects::nonNull).collect(Collectors.toSet())).stream()
                .collect(Collectors.toMap(Account::getId, Account::getEmail));
    }

    private static List<TimelineEntry> timeline(List<MatchEvent> history, TamboMatch state, Map<UUID, String> actors) {
        var undone = history.stream()
                .map(MatchEvent::getTargetEventId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        return history.stream()
                .map(e -> new TimelineEntry(
                        e.getId(),
                        e.getType(),
                        e.getSide(),
                        e.getReason(),
                        actors.get(e.getActorAccountId()),
                        e.getAt(),
                        e.getClockMs(),
                        e.isAutomatic(),
                        undone.contains(e.getId()),
                        state.gaveAutoPoint(e.getId()),
                        e.getOpId(),
                        e.getDeltaMs()))
                .toList();
    }

    private static Review review(Match match, List<RejectedOp> pending, Map<UUID, String> actors) {
        return new Review(
                match.getReviewReason(),
                pending.stream()
                        .map(op -> new ReviewOp(
                                op.getOpId(),
                                op.getType(),
                                op.getSide(),
                                op.getReason(),
                                actors.get(op.getActorAccountId()),
                                op.getAt(),
                                op.getCreatedAt(),
                                op.getCause().name(),
                                op.getDeltaMs()))
                        .toList());
    }

    private Corner corner(Event event, TamboMatch state, Side side, Competitor fighter, Set<UUID> ghosts) {
        var tally = state.corner(side);
        return new Corner(
                fighter.isTeam() ? null : fighter.id(),
                fighter.isTeam() ? String.join(", ", fighter.memberNames()) : fighter.name(),
                ghosts.contains(fighter.id()),
                writer.oneHandRule(event, fighter),
                tally.points(),
                tally.warnings(),
                tally.oneHandWarnings(),
                state.disqualified() == side,
                fighter.isTeam() ? fighter.id() : null,
                fighter.teamNumber(),
                fighter.memberNames());
    }

    private static boolean isReferee(Mat mat, UUID accountId, Set<EventRole> roles) {
        return roles.contains(EventRole.REFEREE) && accountId.equals(mat.getRefereeAccountId());
    }

    /** Null for a team match in the pool. */
    Mat matOrNull(Match match) {
        return match.getMatId() == null ? null : mat(match);
    }

    Mat mat(Match match) {
        return mats.findById(match.getMatId()).orElseThrow(EventException::notFound);
    }
}
