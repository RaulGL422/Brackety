package dev.rgal.brackety.live;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.util.Map;
import java.util.Set;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.HandlerMapping;

/**
 * After any write to an event, its match or group, tells the clients following them. One place for every
 * endpoint, present and future, instead of a call in each service. Topics are worked out before the handler
 * runs: a dissolved group is gone afterwards. The services commit before the response, so a client that
 * fetches on the signal sees the change.
 */
class LiveChangeInterceptor implements HandlerInterceptor {

    private static final String TOPICS = LiveChangeInterceptor.class.getName() + ".topics";
    private static final Set<String> READS = Set.of("GET", "HEAD", "OPTIONS");
    // Nothing was written: the caller was not allowed or the target does not exist.
    private static final Set<Integer> UNCHANGED = Set.of(400, 401, 403, 404);

    private final LiveTopics topics;
    private final LiveHub hub;

    LiveChangeInterceptor(LiveTopics topics, LiveHub hub) {
        this.topics = topics;
        this.hub = hub;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        if (READS.contains(request.getMethod())) {
            return true;
        }
        if (request.getAttribute(HandlerMapping.URI_TEMPLATE_VARIABLES_ATTRIBUTE) instanceof Map<?, ?> variables) {
            @SuppressWarnings("unchecked")
            var changed = topics.changedBy((Map<String, String>) variables);
            if (!changed.isEmpty()) {
                request.setAttribute(TOPICS, changed);
            }
        }
        return true;
    }

    @Override
    public void afterCompletion(
            HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        if (request.getAttribute(TOPICS) instanceof Set<?> changed
                && response.getStatus() < 500
                && !UNCHANGED.contains(response.getStatus())) {
            @SuppressWarnings("unchecked")
            var names = (Set<String>) changed;
            hub.publish(names);
        }
    }
}
