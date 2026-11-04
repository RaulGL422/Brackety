package dev.rgal.brackety.common;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Condition;
import org.springframework.context.annotation.ConditionContext;
import org.springframework.context.annotation.Conditional;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.core.io.Resource;
import org.springframework.core.type.AnnotatedTypeMetadata;
import org.springframework.http.CacheControl;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.servlet.util.matcher.PathPatternRequestMatcher;
import org.springframework.security.web.util.matcher.NegatedRequestMatcher;
import org.springframework.security.web.util.matcher.OrRequestMatcher;
import org.springframework.util.StringUtils;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.resource.PathResourceResolver;

/**
 * Serves the Flutter web build from {@code brackety.web-dir} on the sports hall laptop, same origin as the API
 * (docs/modulos/servidor-local.md). Empty, as in Docker where nginx serves the web, and none of this exists.
 */
@Configuration(proxyBeanMethods = false)
@Conditional(WebAppConfig.WebDirSet.class)
class WebAppConfig implements WebMvcConfigurer {

    private static final String INDEX = "index.html";

    private final String location;

    WebAppConfig(@Value("${brackety.web-dir}") String webDir) {
        var dir = Path.of(webDir).toAbsolutePath().normalize();
        if (!Files.isRegularFile(dir.resolve(INDEX))) {
            throw new IllegalStateException("WEB_DIR has no " + INDEX + ": " + dir);
        }
        var uri = dir.toUri().toString();
        this.location = uri.endsWith("/") ? uri : uri + "/";
    }

    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        registry.addViewController("/").setViewName("forward:/" + INDEX);
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // No-cache (revalidate) for every file, not only index.html: Flutter's file names carry no hash, a 304
        // on the hall's network is cheap and a stale build after an update is not.
        registry.addResourceHandler("/**")
                .addResourceLocations(location)
                .setCacheControl(CacheControl.noCache())
                .resourceChain(false)
                .addResolver(new AppShellResolver());
    }

    // Only the web paths: /api/** and /actuator/** stay with the API chains, exactly as without the web.
    @Bean
    @Order(0)
    SecurityFilterChain webFilterChain(HttpSecurity http) throws Exception {
        var paths = PathPatternRequestMatcher.withDefaults();
        return http.securityMatcher(new NegatedRequestMatcher(
                        new OrRequestMatcher(paths.matcher("/api/**"), paths.matcher("/actuator/**"))))
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(a -> a.anyRequest().permitAll())
                .build();
    }

    // The app uses path URLs (/club/x): a path with no file gets index.html, but never an API path.
    static class AppShellResolver extends PathResourceResolver {

        @Override
        protected Resource getResource(String resourcePath, Resource location) throws IOException {
            if (isApi(resourcePath)) {
                return null;
            }
            var file = super.getResource(resourcePath, location);
            return file != null ? file : super.getResource(INDEX, location);
        }

        private static boolean isApi(String path) {
            return path.equals("api")
                    || path.startsWith("api/")
                    || path.equals("actuator")
                    || path.startsWith("actuator/");
        }
    }

    static class WebDirSet implements Condition {

        @Override
        public boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata) {
            return StringUtils.hasText(context.getEnvironment().getProperty("brackety.web-dir"));
        }
    }
}
