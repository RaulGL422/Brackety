package dev.rgal.brackety.scoreboard;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.live.LiveHub;
import dev.rgal.brackety.live.LiveTopics;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketMessage;
import org.springframework.web.socket.WebSocketSession;

/** The live socket (docs/modulos/tiempo-real.md), driven through the hub with fake connections. */
class ScoreboardLiveTest extends ScoreboardApiTest {

    private static final AtomicInteger IDS = new AtomicInteger();

    @Autowired
    LiveHub hub;

    private final List<Connection> open = new ArrayList<>();

    @AfterEach
    void closeConnections() {
        open.forEach(c -> hub.afterConnectionClosed(c.session, CloseStatus.NORMAL));
    }

    @Test
    void staffFollowingTheEventAndTheMatchHearOfEveryAction() throws Exception {
        var match = match(young, 0, 1);
        var club = connect("club1", LiveTopics.event(eventId), LiveTopics.match(match));
        var helper = connect("ayudante1", LiveTopics.event(eventId));
        var otherMatch = connect("club1", LiveTopics.match(match(young, 2, 3)));
        var otherMat = LiveTopics.mat(matOf(match(older, 0, 1)));
        var otherBoard = connect("arbitro2", otherMat);
        assertThat(club.last()).contains("watching", LiveTopics.event(eventId), LiveTopics.match(match));

        start(match);

        assertThat(club.last()).contains("changed", LiveTopics.event(eventId), LiveTopics.match(match));
        assertThat(helper.last()).contains("changed", LiveTopics.event(eventId));
        assertThat(otherMatch.last()).contains("watching").doesNotContain("changed");
        // A fighter busy on mat 1 changes what mat 2 can start.
        assertThat(otherBoard.last()).contains("changed", otherMat);
    }

    @Test
    void someoneOutsideTheEventCannotFollowIt() throws Exception {
        var match = match(young, 0, 1);
        var outsider = connectAs(outsider(), PASSWORD, LiveTopics.event(eventId), LiveTopics.match(match));

        assertThat(outsider.last()).contains("watching", "\"topics\":[]");
        start(match);
        assertThat(outsider.last()).doesNotContain("changed");
    }

    @Test
    void aBadTokenOrWatchingBeforeSigningInClosesTheSocket() throws Exception {
        var forged = open();
        forged.say("{\"type\":\"auth\",\"token\":\"not-a-token\"}");
        verify(forged.session).close(LiveHub.UNAUTHORIZED);

        var early = open();
        early.say("{\"type\":\"watch\",\"topics\":[\"%s\"]}".formatted(LiveTopics.event(eventId)));
        verify(early.session).close(LiveHub.UNAUTHORIZED);
    }

    @Test
    void aRejectedWriteSendsNothing() throws Exception {
        var match = match(young, 0, 1);
        var club = connect("club1", LiveTopics.match(match));

        // The other mat's referee: 403.
        call(post(path(match) + "/events").content("{\"type\":\"START\",\"knownEvents\":0}"), "arbitro2")
                .andExpect(status().isForbidden());

        assertThat(club.last()).contains("watching");
    }

    private void start(UUID match) throws Exception {
        call(post(path(match) + "/events").content("{\"type\":\"START\",\"knownEvents\":0}"), "arbitro1")
                .andExpect(status().isOk());
    }

    private Connection connect(String username, String... topics) throws Exception {
        return connectAs(username, username, topics);
    }

    private Connection connectAs(String username, String password, String... topics) throws Exception {
        var connection = open();
        var token = auth.login(username, password, "127.0.0.1").accessToken();
        connection.say("{\"type\":\"auth\",\"token\":\"%s\"}".formatted(token));
        assertThat(connection.last()).isEqualTo("{\"type\":\"ready\"}");
        connection.say("{\"type\":\"watch\",\"topics\":[%s]}"
                .formatted(String.join(
                        ",", List.of(topics).stream().map(t -> "\"" + t + "\"").toList())));
        return connection;
    }

    private Connection open() throws Exception {
        var connection = new Connection();
        hub.afterConnectionEstablished(connection.session);
        open.add(connection);
        return connection;
    }

    private class Connection {
        final WebSocketSession session = mock(WebSocketSession.class);
        final List<String> received = new ArrayList<>();

        Connection() throws Exception {
            when(session.getId()).thenReturn("live-" + IDS.incrementAndGet());
            when(session.isOpen()).thenReturn(true);
            doAnswer(call -> received.add(((WebSocketMessage<?>) call.getArgument(0))
                            .getPayload()
                            .toString()))
                    .when(session)
                    .sendMessage(any());
        }

        void say(String text) throws Exception {
            hub.handleMessage(session, new TextMessage(text));
        }

        String last() {
            return received.isEmpty() ? "" : received.getLast();
        }
    }
}
