package dev.rgal.brackety.common;

import java.util.Arrays;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * One block in the log once the server is ready: the version it runs and what is on or off, so a look at
 * {@code docker compose logs api} tells which build is up and what it still lacks. Never a secret or an email.
 */
@Component
class StartupReport {

    private static final Logger log = LoggerFactory.getLogger(StartupReport.class);

    private final Environment env;
    private final JdbcClient jdbc;

    StartupReport(Environment env, JdbcClient jdbc) {
        this.env = env;
        this.jdbc = jdbc;
    }

    @EventListener(ApplicationReadyEvent.class)
    void report() {
        log.info("{}", String.join(System.lineSeparator(), lines()));
    }

    List<String> lines() {
        return List.of(
                "Brackety %s%s is ready (%s)".formatted(version(), commit(), mode()),
                row("Database", database()),
                row("Email", has("brackety.email.resend-api-key") ? "Resend" : "only to this log"),
                row("Google sign-in", has("brackety.auth.google-client-ids") ? "on" : "off"),
                row("Superadmin", superadmin()),
                row(
                        "Privacy contact",
                        has("brackety.legal.privacy-contact-email")
                                ? "set"
                                : "MISSING: events cannot be published nor go to their next phase"),
                row("Participant import", has("ANTHROPIC_API_KEY") ? "on" : "off"),
                row("Demo accounts", flag("brackety.demo.enabled") ? "ON (debug and the hall only)" : "off"),
                row(
                        "Rate limit",
                        "%s requests/min, %s sign-ins/min"
                                .formatted(
                                        env.getProperty("brackety.rate-limit.per-minute"),
                                        env.getProperty("brackety.rate-limit.auth-per-minute"))),
                row("Time zone", env.getProperty("brackety.time-zone", "")));
    }

    private String version() {
        return env.getProperty("brackety.version", "local");
    }

    private String commit() {
        var commit = env.getProperty("brackety.commit", "");
        return commit.isBlank() ? "" : " (" + commit + ")";
    }

    private String mode() {
        if (Arrays.asList(env.getActiveProfiles()).contains("debug")) {
            return "debug: scenarios and simulated clock";
        }
        return has("brackety.web-dir") ? "hall laptop" : "production";
    }

    private String database() {
        var server = jdbc.sql("select current_setting('server_version')")
                .query(String.class)
                .single();
        var schema = jdbc.sql(
                        "select version from flyway_schema_history where success order by installed_rank desc limit 1")
                .query(String.class)
                .optional()
                .orElse("none");
        return "PostgreSQL %s, schema V%s".formatted(server, schema);
    }

    private String superadmin() {
        if (flag("brackety.admin.local-only")) {
            return "only from this computer";
        }
        if (!has("brackety.superadmin.email") || !has("brackety.superadmin.password-hash")) {
            return "closed: no superadmin account";
        }
        return has("brackety.admin.cloudflare-access.team-domain") && has("brackety.admin.cloudflare-access.audience")
                ? "behind Cloudflare Access"
                : "closed: no Cloudflare Access settings (503)";
    }

    private boolean has(String key) {
        return !env.getProperty(key, "").isBlank();
    }

    private boolean flag(String key) {
        return env.getProperty(key, Boolean.class, false);
    }

    private static String row(String name, String value) {
        return "  %-19s %s".formatted(name, value);
    }
}
