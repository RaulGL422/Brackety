package dev.rgal.brackety.scoreboard;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import dev.rgal.brackety.event.EventService;
import java.time.Duration;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Server battery, «Concurrencia» (docs/04-testing.md, GR-8): the club finishes the phase while a referee's start or
 * reopen is on its way. The action saw the phase in progress, then waited for the event row the finish held; once
 * it gets it the phase is finished, so it must be refused and no match may be left in progress. Deterministic: a
 * transaction plays the finish and holds the event row until the action is waiting for it.
 */
class PhaseRaceTest extends ScoreboardApiTest {

    @Autowired
    EventService eventService;

    @Autowired
    PlatformTransactionManager transactions;

    @Test
    void aStartThatWaitedForTheFinishingPhaseIsRefused() throws Exception {
        var match = match(young, 0, 1);

        assertThat(whileThePhaseFinishes(match, "{\"type\":\"START\",\"knownEvents\":0}"))
                .isEqualTo(409);

        assertThat(status(match)).isEqualTo("PENDING");
    }

    @Test
    void aReopenThatWaitedForTheFinishingPhaseIsRefused() throws Exception {
        var match = match(young, 0, 1);
        act(match, "{\"type\":\"START\",\"knownEvents\":0}");
        clock.advance(Duration.ofMinutes(10));
        act(match, "{\"type\":\"FINISH\",\"knownEvents\":1}");

        assertThat(whileThePhaseFinishes(match, "{\"type\":\"REOPEN\",\"reason\":\"Corregir\",\"knownEvents\":2}"))
                .isEqualTo(409);

        assertThat(status(match)).isEqualTo("FINISHED");
    }

    private int whileThePhaseFinishes(UUID match, String action) throws Exception {
        var locked = new CountDownLatch(1);
        var release = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var finishing = pool.submit(() -> new TransactionTemplate(transactions).executeWithoutResult(status -> {
                eventService.lock(eventId);
                jdbc.sql("update event set finished_at = now() where id = ?")
                        .param(eventId)
                        .update();
                locked.countDown();
                await(release);
            }));
            assertThat(locked.await(10, TimeUnit.SECONDS)).isTrue();

            var answer = pool.submit(() -> call(post(path(match) + "/events").content(action), "arbitro1")
                    .andReturn()
                    .getResponse()
                    .getStatus());
            assertThatThrownBy(() -> answer.get(500, TimeUnit.MILLISECONDS)).isInstanceOf(TimeoutException.class);

            release.countDown();
            finishing.get(10, TimeUnit.SECONDS);
            return answer.get(10, TimeUnit.SECONDS);
        }
    }

    private void act(UUID match, String action) throws Exception {
        var status = call(post(path(match) + "/events").content(action), "arbitro1")
                .andReturn()
                .getResponse()
                .getStatus();
        assertThat(status).isEqualTo(200);
    }

    private String status(UUID match) {
        return jdbc.sql("select status from fight_match where id = ?")
                .param(match)
                .query(String.class)
                .single();
    }

    private static void await(CountDownLatch latch) {
        try {
            latch.await(10, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
