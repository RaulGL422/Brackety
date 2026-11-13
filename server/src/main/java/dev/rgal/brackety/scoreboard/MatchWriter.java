package dev.rgal.brackety.scoreboard;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.grouping.Competitor;
import dev.rgal.brackety.grouping.CompetitorDirectory;
import dev.rgal.brackety.grouping.Match;
import dev.rgal.brackety.grouping.MatchRepository;
import dev.rgal.brackety.participant.ParticipantRepository;
import dev.rgal.brackety.scoreboard.RejectedOp.Cause;
import dev.rgal.brackety.scoreboard.TamboMatch.Rules;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Component;

/** Appends actions to a locked match with the scoreboard rules, and keeps the match's snapshot in step. */
@Component
class MatchWriter {

    // Reglamento tambo: from 4 to 8 (both hands always, the F1's 5-8 category), touching with one hand is warned
    // and, twice, scores for the rival.
    static final int ONE_HAND_MIN_AGE = 4;
    static final int ONE_HAND_MAX_AGE = 8;

    /** {@code deltaMs}: only for a CLOCK_ADJUST. {@code opId}: the device's id, or null from the web. */
    record Action(MatchEventType type, Side side, String reason, Long deltaMs, UUID opId, UUID actorAccountId) {}

    record Refusal(Cause cause, String detail) {}

    private final MatchRepository matches;
    private final MatchEventRepository matchEvents;
    private final ParticipantRepository participants;
    private final CompetitorDirectory directory;
    private final EventService events;

    MatchWriter(
            MatchRepository matches,
            MatchEventRepository matchEvents,
            ParticipantRepository participants,
            CompetitorDirectory directory,
            EventService events) {
        this.matches = matches;
        this.matchEvents = matchEvents;
        this.participants = participants;
        this.directory = directory;
        this.events = events;
    }

    /**
     * Appends {@code action} as done at {@code now} to {@code history} (the match's events, which grows),
     * or says why it cannot happen. {@code checkOtherMats}: refuse a first start if a fighter is fighting
     * on another mat. {@code checkRest}: also if a fighter has not had the event's least rest since their last
     * match (online only: a device without network already started it, and the club review applies what happened).
     */
    Optional<Refusal> append(
            Match match,
            Event event,
            List<MatchEvent> history,
            Action action,
            Instant now,
            boolean checkOtherMats,
            boolean checkRest) {
        var state = replay(event, match, history);
        var refusal = refusal(match, event, state, action, now, checkOtherMats, checkRest);
        if (refusal.isPresent()) {
            return refusal;
        }
        var target = action.type() == MatchEventType.UNDO
                ? state.lastUndoable().orElseThrow().id()
                : null;
        history.add(matchEvents.save(new MatchEvent(
                match.getId(),
                history.size(),
                action.type(),
                action.side(),
                action.reason(),
                target,
                action.actorAccountId(),
                false,
                now,
                state.elapsedAt(now),
                action.opId(),
                action.deltaMs())));
        stopIfOverAndSnapshot(match, event, history, action, now);
        return Optional.empty();
    }

    /** The device's time for an action, kept between the match's last action and the server's time. */
    static Instant effectiveTime(List<MatchEvent> history, Instant at, Instant serverNow) {
        if (at == null || at.isAfter(serverNow)) {
            return serverNow;
        }
        var last = history.isEmpty() ? null : history.getLast().getAt();
        return last != null && at.isBefore(last) ? last : at;
    }

    /** What the device counts in {@code knownEvents}: the automatic stops are left out. */
    static int knownEvents(List<MatchEvent> history) {
        return (int) history.stream().filter(e -> !e.isAutomatic()).count();
    }

    // A team follows the rule if any of its members is young enough.
    boolean oneHandRule(Event event, Competitor fighter) {
        return participants.findAllById(fighter.participantIds()).stream()
                .map(p -> event.ageOf(p.getBirthDate()))
                .anyMatch(MatchWriter::oneHandAge);
    }

    static boolean oneHandAge(int age) {
        return age >= ONE_HAND_MIN_AGE && age <= ONE_HAND_MAX_AGE;
    }

    static TamboMatch replay(Event event, Match match, List<MatchEvent> history) {
        var teams = match.isTeamMatch();
        return TamboMatch.replay(
                new Rules(Duration.ofSeconds(event.matchSecondsFor(teams)), event.pointsLimitFor(teams)),
                history.stream().map(MatchEvent::toEntry).toList());
    }

    private Optional<Refusal> refusal(
            Match match,
            Event event,
            TamboMatch state,
            Action action,
            Instant now,
            boolean checkOtherMats,
            boolean checkRest) {
        var rules = state.refuse(action.type(), action.side(), action.deltaMs() == null ? 0 : action.deltaMs(), now);
        if (rules.isPresent()) {
            return Optional.of(new Refusal(Cause.RULES, rules.get()));
        }
        // Reopening takes the mat and the fighters again, as a first start does.
        if ((action.type() == MatchEventType.START && !state.isStarted()) || action.type() == MatchEventType.REOPEN) {
            var start = startRefusal(match, checkOtherMats);
            if (start.isPresent()) {
                return start;
            }
        }
        // Not on a reopen: the fighters' last match is this very one.
        if (checkRest && action.type() == MatchEventType.START && !state.isStarted()) {
            var rested = restRefusal(match, event, now);
            if (rested.isPresent()) {
                return rested;
            }
        }
        if (action.type() == MatchEventType.ONE_HAND_WARNING && !oneHandRule(event, fighter(match, action.side()))) {
            return Optional.of(new Refusal(Cause.AGE, "The one-hand warning is only for fighters aged 4 to 7."));
        }
        return Optional.empty();
    }

    // Two mats starting at once with a shared fighter would each see the other still pending: the event lock
    // (held until commit) makes the second wait and see the first in progress. Always match, then event.
    private Optional<Refusal> startRefusal(Match match, boolean checkOtherMats) {
        events.lock(match.getEventId());
        var inProgress = matches.findByEventId(match.getEventId()).stream()
                .filter(m ->
                        m.getStatus() == Match.Status.IN_PROGRESS && !m.getId().equals(match.getId()))
                .toList();
        if (inProgress.stream().anyMatch(m -> match.getMatId().equals(m.getMatId()))) {
            return Optional.of(new Refusal(Cause.MAT_BUSY, "Another match is in progress on this mat."));
        }
        var competitors = directory.of(match.getEventId());
        var fighters = competitors.participants(match.getRedId(), match.getBlueId());
        if (checkOtherMats
                && inProgress.stream()
                        .flatMap(m -> competitors.participants(m.getRedId(), m.getBlueId()).stream())
                        .anyMatch(fighters::contains)) {
            return Optional.of(new Refusal(Cause.FIGHTER_BUSY, "A fighter is in a match on another mat."));
        }
        return Optional.empty();
    }

    // The least rest between two matches of a person, on any mat (Raul, 2026-11-13): the board already shows
    // it, this stops a stale screen or a second device.
    private Optional<Refusal> restRefusal(Match match, Event event, Instant now) {
        return restedAt(match, event)
                .filter(readyAt -> readyAt.isAfter(now))
                .map(readyAt ->
                        new Refusal(Cause.FIGHTER_RESTING, "A fighter is still resting until " + readyAt + "."));
    }

    /** When every fighter of {@code match} has had the least rest since their last other match; empty if none. */
    Optional<Instant> restedAt(Match match, Event event) {
        if (match.isRestWaived()) {
            return Optional.empty();
        }
        var competitors = directory.of(match.getEventId());
        var fighters = competitors.participants(match.getRedId(), match.getBlueId());
        var minRest = Duration.ofSeconds(event.getMinRestSeconds());
        return matches.findByEventId(match.getEventId()).stream()
                .filter(m -> !m.getId().equals(match.getId()) && m.getFinishedAt() != null)
                .filter(m -> competitors.participants(m.getRedId(), m.getBlueId()).stream()
                        .anyMatch(fighters::contains))
                .map(m -> m.getFinishedAt().plus(minRest))
                .max(Instant::compareTo);
    }

    // Points or a disqualification end the match: the clock stops here and stays stopped after an undo.
    private void stopIfOverAndSnapshot(Match match, Event event, List<MatchEvent> history, Action action, Instant now) {
        var state = replay(event, match, history);
        var endsNow =
                state.endReason(now).filter(r -> r != TamboMatch.EndReason.TIME).isPresent();
        if (endsNow && state.isRunning(now)) {
            history.add(matchEvents.save(new MatchEvent(
                    match.getId(),
                    history.size(),
                    MatchEventType.STOP,
                    null,
                    null,
                    null,
                    action.actorAccountId(),
                    true,
                    now,
                    state.elapsedAt(now),
                    null,
                    null)));
            state = replay(event, match, history);
        }
        match.updateFromScoreboard(
                state.corner(Side.RED).points(),
                state.corner(Side.BLUE).points(),
                state.elapsedAt(now),
                state.isRunning(now) ? now : null,
                state.disqualified() == null ? null : state.disqualified().name(),
                state.isStarted(),
                state.isFinished(),
                now);
    }

    private Competitor fighter(Match match, Side side) {
        return directory.of(match.getEventId()).get(side == Side.RED ? match.getRedId() : match.getBlueId());
    }
}
