package dev.rgal.brackety.live;

import dev.rgal.brackety.auth.session.SessionService;
import java.io.IOException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.ConcurrentWebSocketSessionDecorator;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/**
 * Server push for screens that follow an event (docs/modulos/tiempo-real.md). A plain WebSocket that only says
 * "this changed": the client fetches it again by REST, so the views and their permission checks stay in one
 * place and a lost message costs nothing but a delay.
 *
 * <p>Client to server: {@code {"type":"auth","token":"<access token>"}} first (in the message, not the URL, so
 * no proxy or log keeps it), then {@code {"type":"watch","topics":[...]}} with the whole set it wants. Server to
 * client: {@code ready}, {@code watching} (the topics it may follow), {@code changed} (topics) and {@code ping}.
 */
@Component
public class LiveHub extends TextWebSocketHandler {

    /** The token was missing, invalid or has expired: the client gets a new one and connects again. */
    public static final CloseStatus UNAUTHORIZED = new CloseStatus(4001, "Unauthorized");

    static final Duration AUTH_WINDOW = Duration.ofSeconds(10);
    private static final int MAX_TOPICS = 100;
    private static final int SEND_TIME_LIMIT_MS = 5_000;
    private static final int BUFFER_LIMIT_BYTES = 64 * 1024;

    private static final Logger log = LoggerFactory.getLogger(LiveHub.class);

    private final Map<String, Client> clients = new ConcurrentHashMap<>();
    private final JwtDecoder jwtDecoder;
    private final LiveTopics topics;
    private final JsonMapper json;
    private final Clock clock;

    LiveHub(JwtDecoder jwtDecoder, LiveTopics topics, JsonMapper json, Clock clock) {
        this.jwtDecoder = jwtDecoder;
        this.topics = topics;
        this.json = json;
        this.clock = clock;
    }

    private static final class Client {
        // Sends come from many threads (every write of the API) to one socket: the decorator queues them.
        final WebSocketSession session;
        final Instant openedAt;
        volatile UUID accountId;
        volatile Instant expiresAt;
        // Each topic the client follows, by the published topic it hears from (a mat hears from its event).
        volatile Map<String, String> topics = Map.of();

        Client(WebSocketSession session, Instant openedAt) {
            this.session = session;
            this.openedAt = openedAt;
        }
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        clients.put(
                session.getId(),
                new Client(
                        new ConcurrentWebSocketSessionDecorator(session, SEND_TIME_LIMIT_MS, BUFFER_LIMIT_BYTES),
                        clock.instant()));
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        clients.remove(session.getId());
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        var client = clients.get(session.getId());
        if (client == null) {
            return;
        }
        JsonNode body;
        try {
            body = json.readTree(message.getPayload());
        } catch (JacksonException e) {
            close(client, CloseStatus.BAD_DATA);
            return;
        }
        switch (body.path("type").asString("")) {
            case "auth" -> authenticate(client, body.path("token").asString(""));
            case "watch" -> watch(client, body.path("topics"));
            default -> close(client, CloseStatus.BAD_DATA);
        }
    }

    private void authenticate(Client client, String token) {
        try {
            var jwt = jwtDecoder.decode(token);
            // The event endpoints need a verified email too (RequiresVerifiedEmail).
            if (!Boolean.TRUE.equals(jwt.getClaimAsBoolean(SessionService.EMAIL_VERIFIED_CLAIM))) {
                close(client, UNAUTHORIZED);
                return;
            }
            client.accountId = UUID.fromString(jwt.getSubject());
            client.expiresAt = jwt.getExpiresAt();
            send(client, Map.of("type", "ready"));
        } catch (JwtException | IllegalArgumentException e) {
            close(client, UNAUTHORIZED);
        }
    }

    private void watch(Client client, JsonNode wanted) {
        var accountId = client.accountId;
        if (accountId == null) {
            close(client, UNAUTHORIZED);
            return;
        }
        var asked = new LinkedHashSet<String>();
        for (var topic : wanted) {
            if (asked.size() < MAX_TOPICS) {
                asked.add(topic.asString(""));
            }
        }
        var followed = new LinkedHashMap<String, String>();
        for (var topic : asked) {
            topics.source(accountId, topic).ifPresent(source -> followed.put(topic, source));
        }
        client.topics = Map.copyOf(followed);
        send(client, Map.of("type", "watching", "topics", List.copyOf(followed.keySet())));
    }

    /** Tells every client following any of {@code changed} that it changed. */
    public void publish(Collection<String> changed) {
        for (var client : clients.values()) {
            var theirs = client.topics.entrySet().stream()
                    .filter(followed -> changed.contains(followed.getValue()))
                    .map(Map.Entry::getKey)
                    .toList();
            if (!theirs.isEmpty()) {
                send(client, Map.of("type", "changed", "topics", theirs));
            }
        }
    }

    // Keeps idle connections open through proxies (Cloudflare closes them after 100 s) and lets the client notice a
    // dead one. Closes the ones that never signed in and those whose token has expired.
    @Scheduled(fixedDelayString = "PT25S", initialDelayString = "PT25S")
    void keepAlive() {
        var now = clock.instant();
        for (var client : clients.values()) {
            if (client.accountId == null) {
                if (client.openedAt.plus(AUTH_WINDOW).isBefore(now)) {
                    close(client, UNAUTHORIZED);
                }
            } else if (client.expiresAt != null && !client.expiresAt.isAfter(now)) {
                close(client, UNAUTHORIZED);
            } else {
                send(client, Map.of("type", "ping"));
            }
        }
    }

    private void send(Client client, Map<String, ?> message) {
        try {
            client.session.sendMessage(new TextMessage(json.writeValueAsString(message)));
        } catch (IOException | RuntimeException e) {
            // A slow or broken client must not hold back the others: it reconnects and fetches again.
            log.debug("Closing live client {}: {}", client.session.getId(), e.toString());
            close(client, CloseStatus.SESSION_NOT_RELIABLE);
        }
    }

    private void close(Client client, CloseStatus status) {
        clients.remove(client.session.getId());
        try {
            client.session.close(status);
        } catch (IOException e) {
            // Already gone.
        }
    }
}
