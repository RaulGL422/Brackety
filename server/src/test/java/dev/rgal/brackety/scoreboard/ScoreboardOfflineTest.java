package dev.rgal.brackety.scoreboard;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.junit.jupiter.api.Assertions.assertThrows;

import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.scoreboard.ScoreboardService.Recorded;
import dev.rgal.brackety.scoreboard.dto.MatchEventRequest;
import dev.rgal.brackety.scoreboard.dto.MatchView;
import dev.rgal.brackety.scoreboard.dto.MatchView.ReviewOp;
import dev.rgal.brackety.scoreboard.dto.MatchView.TimelineEntry;
import dev.rgal.brackety.scoreboard.dto.ReviewRequest;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

// Actions from the Android queue (docs/modulos/offline.md): with opId, at and knownEvents.
class ScoreboardOfflineTest extends ScoreboardApiTest {

    @Autowired
    ScoreboardService scoreboard;

    @Autowired
    MatchReviewService reviews;

    @Autowired
    EventService eventService;

    @Autowired
    PlatformTransactionManager transactions;

    UUID match;
    Instant t0;

    @BeforeEach
    void pickMatch() {
        match = match(young, 0, 1);
        t0 = clock.instant();
    }

    @Test
    void withAnOpIdItWorksAsWithout() {
        offline(MatchEventType.START, null, t0, 0);
        var view = offline(MatchEventType.POINT, Side.RED, t0, 1).view();

        assertThat(view.red().points()).isEqualTo(1);
        assertThat(view.running()).isTrue();
        assertThat(view.serverTime()).isEqualTo(clock.instant());
        assertThat(view.review()).isNull();
    }

    @Test
    void aPointBeforeStartIsARulesClash() {
        assertThat(offline(MatchEventType.POINT, Side.RED, t0, 0).conflictCode())
                .isEqualTo("MATCH_CONFLICT");

        var review = view().review();
        assertThat(review.reason()).isEqualTo("RULES");
        assertThat(review.ops()).extracting(ReviewOp::cause).containsExactly("RULES");
        assertThat(view().red().points()).isZero();
    }

    // Deterministic instead of racing two starts on two mats: while another transaction holds the event row
    // (as the other start would), a first start waits for it before looking at the other mats.
    @Test
    void aFirstStartWaitsForTheEventLock() throws Exception {
        var locked = new CountDownLatch(1);
        var release = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var holder = pool.submit(() -> new TransactionTemplate(transactions).executeWithoutResult(status -> {
                eventService.lock(eventId);
                locked.countDown();
                await(release);
            }));
            assertThat(locked.await(10, TimeUnit.SECONDS)).isTrue();

            var start = pool.submit(() -> offline(MatchEventType.START, null, t0, 0));
            assertThatThrownBy(() -> start.get(500, TimeUnit.MILLISECONDS)).isInstanceOf(TimeoutException.class);

            release.countDown();
            holder.get(10, TimeUnit.SECONDS);
            assertThat(start.get(10, TimeUnit.SECONDS).view().running()).isTrue();
        }
    }

    @Test
    void aRetryOfTheSameOpIdIsAnsweredLikeTheFirstTimeWithoutWriting() {
        var start = request(MatchEventType.START, null, UUID.randomUUID(), t0, 0);
        scoreboard.record(match, referee(), start);
        var again = scoreboard.record(match, referee(), start);

        assertThat(again.conflictCode()).isNull();
        assertThat(again.view().timeline()).extracting(TimelineEntry::opId).containsExactly(start.opId());

        var stale = request(MatchEventType.POINT, Side.RED, UUID.randomUUID(), t0, 0);
        assertThat(scoreboard.record(match, referee(), stale).conflictCode()).isEqualTo("MATCH_CONFLICT");
        assertThat(scoreboard.record(match, referee(), stale).conflictCode()).isEqualTo("MATCH_CONFLICT");
        assertThat(rejectedRows()).isEqualTo(1);
    }

    @Test
    void theTimeIsKeptBetweenTheLastActionAndNow() {
        offline(MatchEventType.START, null, t0.plus(Duration.ofHours(1)), 0);
        clock.advance(Duration.ofSeconds(30));
        var view = offline(MatchEventType.POINT, Side.RED, t0.minus(Duration.ofMinutes(5)), 1)
                .view();

        assertThat(view.timeline()).extracting(TimelineEntry::at).containsExactly(t0, t0);
        assertThat(view.timeline().get(1).clockMs()).isZero();
        assertThat(view.remainingMs()).isEqualTo(150_000);
    }

    @Test
    void aMatchPlayedOfflineEndsWithTheClockOfItsActions() {
        clock.advance(Duration.ofMinutes(10));
        offline(MatchEventType.START, null, t0, 0);
        offline(MatchEventType.POINT, Side.RED, t0.plusSeconds(30), 1);
        var view = offline(MatchEventType.STOP, null, t0.plusSeconds(90), 2).view();

        assertThat(view.running()).isFalse();
        assertThat(view.remainingMs()).isEqualTo(90_000);
        assertThat(view.timeline()).extracting(TimelineEntry::clockMs).containsExactly(0L, 30_000L, 90_000L);
        assertThat(startedAt()).isEqualTo(t0);
    }

    @Test
    void theTimeRunsOutAtTheActionsTime() {
        clock.advance(Duration.ofMinutes(10));
        offline(MatchEventType.START, null, t0, 0);
        var finish = offline(MatchEventType.FINISH, null, t0.plusSeconds(180), 1);

        assertThat(finish.view().status().name()).isEqualTo("FINISHED");
        assertThat(finish.view().endReason()).isEqualTo("TIME");
        assertThat(jdbc.sql("select finished_at from fight_match where id = ?")
                        .param(match)
                        .query(Instant.class)
                        .single())
                .isEqualTo(t0.plusSeconds(180));
    }

    @Test
    void anotherDeviceWritingPutsTheMatchInReviewAndKeepsEveryAction() {
        offline(MatchEventType.START, null, t0, 0);

        assertThat(offline(MatchEventType.POINT, Side.RED, t0, 0).conflictCode())
                .isEqualTo("MATCH_CONFLICT");
        assertThat(offline(MatchEventType.POINT, Side.BLUE, t0, 2).conflictCode())
                .isEqualTo("MATCH_IN_REVIEW");

        var review = view().review();
        assertThat(review.reason()).isEqualTo("KNOWN_EVENTS");
        assertThat(review.ops()).extracting(ReviewOp::side).containsExactly(Side.RED, Side.BLUE);
        assertThat(review.ops()).extracting(ReviewOp::cause).containsExactly("KNOWN_EVENTS", "IN_REVIEW");
        assertThat(review.ops().getFirst().actor()).isEqualTo("arbitro1");
        assertThat(view().red().points()).isZero();
        assertThat(rejectedRows()).isEqualTo(2);
    }

    @Test
    void anOfflineStartWithAFighterOnAnotherMatClashes() {
        var otherMat = match(young, 0, 2);
        jdbc.sql("update fight_match set mat_id = ? where id = ?")
                .params(matOf(match(older, 0, 1)), otherMat)
                .update();
        offline(MatchEventType.START, null, t0, 0);

        var start = scoreboard.record(
                otherMat, accountId("arbitro2"), request(MatchEventType.START, null, UUID.randomUUID(), t0, 0));

        assertThat(start.conflictCode()).isEqualTo("MATCH_CONFLICT");
        assertThat(reviewReason(otherMat)).isEqualTo("FIGHTER_BUSY");
    }

    @Test
    void inReviewTheWebGetsAConflictAndNothingIsSaved() {
        offline(MatchEventType.START, null, t0, 0);
        offline(MatchEventType.POINT, Side.RED, t0, 5);

        var refused = assertThrows(
                EventException.class,
                () -> scoreboard.record(match, referee(), request(MatchEventType.POINT, Side.RED, null, null, 1)));

        assertThat(refused.getBody().getProperties()).containsEntry("code", "MATCH_IN_REVIEW");
        assertThat(rejectedRows()).isEqualTo(1);
        assertThat(view().timeline()).hasSize(1);
    }

    @Test
    void everyActionNeedsKnownEvents() {
        var refused = assertThrows(
                EventException.class,
                () -> scoreboard.record(
                        match, referee(), request(MatchEventType.START, null, UUID.randomUUID(), t0, null)));
        var web = assertThrows(
                EventException.class,
                () -> scoreboard.record(match, referee(), request(MatchEventType.START, null, null, null, null)));

        assertThat(refused.getStatusCode().value()).isEqualTo(400);
        assertThat(web.getStatusCode().value()).isEqualTo(400);
    }

    @Test
    void automaticStopsDoNotCountAsKnownEvents() {
        offline(MatchEventType.START, null, t0, 0);
        var disqualified = offline(MatchEventType.DISQUALIFICATION, Side.RED, t0.plusSeconds(10), 1);
        assertThat(disqualified.view().timeline()).hasSize(3);

        var undo = offline(MatchEventType.UNDO, null, t0.plusSeconds(20), 2);

        assertThat(undo.conflictCode()).isNull();
        assertThat(undo.view().red().disqualified()).isFalse();
        assertThat(undo.view().running()).isFalse();
    }

    @Test
    void applyingAddsTheActionsInOrderAndSkipsThoseTheRulesRefuse() {
        clock.advance(Duration.ofMinutes(5));
        offline(MatchEventType.START, null, t0, 0);
        offline(MatchEventType.POINT, Side.RED, t0.plusSeconds(10), 0);
        offline(MatchEventType.POINT, Side.BLUE, t0.plusSeconds(20), 2);
        offline(MatchEventType.FINISH, null, t0.plusSeconds(30), 3);
        offline(MatchEventType.UNDO, null, t0.plusSeconds(40), 4);

        var applied = reviews.review(match, club(), new ReviewRequest(ReviewRequest.Action.APPLY));

        assertThat(applied.applied()).isEqualTo(3);
        assertThat(applied.skipped()).isEqualTo(1);
        var view = applied.match();
        assertThat(view.review()).isNull();
        assertThat(view.red().points()).isEqualTo(1);
        assertThat(view.blue().points()).isZero();
        assertThat(view.timeline())
                .extracting(TimelineEntry::type)
                .containsExactly(MatchEventType.START, MatchEventType.POINT, MatchEventType.POINT, MatchEventType.UNDO);
        assertThat(view.timeline()).extracting(TimelineEntry::actor).containsOnly("arbitro1");
        assertThat(view.timeline().get(3).at()).isEqualTo(t0.plusSeconds(40));
        assertThat(resolutions()).containsExactly("APPLIED", "APPLIED", "SKIPPED", "APPLIED");
        assertThat(offline(MatchEventType.POINT, Side.RED, t0.plusSeconds(50), 4)
                        .conflictCode())
                .isNull();
    }

    @Test
    void applyingCanFinishTheMatchAndUpdatesItsScore() {
        offline(MatchEventType.START, null, t0, 0);
        offline(MatchEventType.POINT, Side.BLUE, t0, 1);
        offline(MatchEventType.DISQUALIFICATION, Side.RED, t0, 0);
        offline(MatchEventType.FINISH, null, t0, 2);

        var applied = reviews.review(match, club(), new ReviewRequest(ReviewRequest.Action.APPLY));

        assertThat(applied.applied()).isEqualTo(2);
        assertThat(applied.match().status().name()).isEqualTo("FINISHED");
        assertThat(applied.match().red().disqualified()).isTrue();
        assertThat(jdbc.sql("select disqualified_side from fight_match where id = ?")
                        .param(match)
                        .query(String.class)
                        .single())
                .isEqualTo("RED");
    }

    @Test
    void discardingAppliesNothingAndTheMatchGoesOn() {
        offline(MatchEventType.START, null, t0, 0);
        offline(MatchEventType.POINT, Side.RED, t0, 0);

        var discarded = reviews.review(match, club(), new ReviewRequest(ReviewRequest.Action.DISCARD));

        assertThat(discarded.applied()).isZero();
        assertThat(discarded.match().review()).isNull();
        assertThat(discarded.match().red().points()).isZero();
        assertThat(resolutions()).containsExactly("DISCARDED");
        assertThat(jdbc.sql("select count(*) from offline_rejected_op where resolved_by = ? and resolved_at = ?")
                        .params(club(), clock.instant().atOffset(ZoneOffset.UTC))
                        .query(Integer.class)
                        .single())
                .isEqualTo(1);
        var web = scoreboard.record(
                match, referee(), request(MatchEventType.POINT, Side.BLUE, null, null, knownEvents(match)));
        assertThat(web.view().blue().points()).isEqualTo(1);
    }

    private static void await(CountDownLatch latch) {
        try {
            latch.await(10, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private Recorded offline(MatchEventType type, Side side, Instant at, int knownEvents) {
        return scoreboard.record(match, referee(), request(type, side, UUID.randomUUID(), at, knownEvents));
    }

    private static MatchEventRequest request(MatchEventType type, Side side, UUID opId, Instant at, Integer known) {
        var reason = type == MatchEventType.DISQUALIFICATION || type == MatchEventType.WARNING ? "Motivo" : null;
        return new MatchEventRequest(type, side, reason, opId, at, known, null);
    }

    private MatchView view() {
        return scoreboard.view(match, club());
    }

    private UUID referee() {
        return accountId("arbitro1");
    }

    private UUID club() {
        return accountId("club1");
    }

    private int rejectedRows() {
        return jdbc.sql("select count(*) from offline_rejected_op where match_id = ?")
                .param(match)
                .query(Integer.class)
                .single();
    }

    private List<String> resolutions() {
        return jdbc.sql("select resolution from offline_rejected_op where match_id = ? order by position")
                .param(match)
                .query(String.class)
                .list();
    }

    private String reviewReason(UUID id) {
        return jdbc.sql("select review_reason from fight_match where id = ?")
                .param(id)
                .query(String.class)
                .single();
    }

    private Instant startedAt() {
        return jdbc.sql("select started_at from fight_match where id = ?")
                .param(match)
                .query(Instant.class)
                .single();
    }
}
