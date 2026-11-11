package dev.rgal.brackety.live;

import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.handler.MappedInterceptor;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

// Not a WebMvcConfigurer: @WebMvcTest slices load every one, and they have no live socket (no LiveHub).
@Configuration(proxyBeanMethods = false)
@EnableWebSocket
class LiveConfig implements WebSocketConfigurer {

    static final String PATH = "/api/v1/live";

    private final LiveHub hub;
    private final String[] allowedOriginPatterns;

    LiveConfig(LiveHub hub, @Value("${brackety.cors.allowed-origin-patterns}") List<String> allowedOriginPatterns) {
        this.hub = hub;
        this.allowedOriginPatterns =
                allowedOriginPatterns.stream().filter(p -> !p.isBlank()).toArray(String[]::new);
    }

    // The same origins as CORS (CorsConfig). The same origin (the sports hall laptop) and the Android app, which
    // sends no Origin, always pass.
    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(hub, PATH).setAllowedOriginPatterns(allowedOriginPatterns);
    }

    // Spring MVC picks up MappedInterceptor beans by itself.
    @Bean
    MappedInterceptor liveChangeInterceptor(LiveTopics topics) {
        return new MappedInterceptor(new String[] {"/api/**"}, new LiveChangeInterceptor(topics, hub));
    }
}
