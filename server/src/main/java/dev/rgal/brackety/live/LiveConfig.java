package dev.rgal.brackety.live;

import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration(proxyBeanMethods = false)
@EnableWebSocket
class LiveConfig implements WebSocketConfigurer, WebMvcConfigurer {

    static final String PATH = "/api/v1/live";

    private final LiveHub hub;
    private final LiveChangeInterceptor interceptor;
    private final String[] allowedOriginPatterns;

    LiveConfig(
            LiveHub hub,
            LiveChangeInterceptor interceptor,
            @Value("${brackety.cors.allowed-origin-patterns}") List<String> allowedOriginPatterns) {
        this.hub = hub;
        this.interceptor = interceptor;
        this.allowedOriginPatterns =
                allowedOriginPatterns.stream().filter(p -> !p.isBlank()).toArray(String[]::new);
    }

    // The same origins as CORS (CorsConfig). The same origin (the sports hall laptop) and the Android app, which
    // sends no Origin, always pass.
    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(hub, PATH).setAllowedOriginPatterns(allowedOriginPatterns);
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(interceptor).addPathPatterns("/api/**");
    }
}
