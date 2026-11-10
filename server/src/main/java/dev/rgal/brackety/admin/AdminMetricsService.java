package dev.rgal.brackety.admin;

import dev.rgal.brackety.admin.dto.AdminMetrics;
import dev.rgal.brackety.admin.dto.AdminMetrics.Activity;
import dev.rgal.brackety.admin.dto.AdminMetrics.Events;
import dev.rgal.brackety.admin.dto.AdminMetrics.Server;
import dev.rgal.brackety.admin.dto.AdminMetrics.Users;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import java.sql.Timestamp;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Counts for the superadmin's dashboard, read from the database in a few queries; nothing new is stored. */
@Service
class AdminMetricsService {

    private static final String[] PROFILES = {"CLUB", "EXTERNAL_ENTITY", "HELPER", "STUDENT", "EXTERNAL"};

    private final JdbcClient jdbc;
    private final MeterRegistry meters;
    private final Clock clock;
    // The service starts with the application: close enough to tell how long the 5xx count covers.
    private final Instant startedAt;

    AdminMetricsService(JdbcClient jdbc, MeterRegistry meters, Clock clock) {
        this.jdbc = jdbc;
        this.meters = meters;
        this.clock = clock;
        this.startedAt = clock.instant();
    }

    @Transactional(readOnly = true)
    public AdminMetrics read() {
        var now = clock.instant();
        return new AdminMetrics(now, users(now), events(now), activity(now), new Server(startedAt, serverErrors()));
    }

    private Users users(Instant now) {
        var weekAgo = Timestamp.from(now.minus(Duration.ofDays(7)));
        var at = Timestamp.from(now);
        return jdbc.sql("""
                        select
                          (select count(*) from account where status = 'ACTIVE') as active,
                          (select count(*) from account where status = 'ACTIVE' and not email_verified) as unverified,
                          (select count(*) from account where status = 'ACTIVE' and created_at >= :weekAgo) as new7,
                          (select count(*) from account where status = 'DELETED') as deleting,
                          (select count(distinct p.account_id) from profile p join account a on a.id = p.account_id
                             where a.status = 'ACTIVE' and p.type in ('CLUB', 'EXTERNAL_ENTITY')
                             and not p.validated) as organizers,
                          (select count(distinct family_id) from refresh_token
                             where revoked_at is null and used_at is null and expires_at > :now) as sessions,
                          (select count(*) from login_attempt where locked_until > :now) as locks""")
                .param("weekAgo", weekAgo)
                .param("now", at)
                .query((rs, n) -> new Users(
                        rs.getLong("active"),
                        rs.getLong("unverified"),
                        rs.getLong("new7"),
                        rs.getLong("deleting"),
                        rs.getLong("organizers"),
                        rs.getLong("sessions"),
                        rs.getLong("locks"),
                        byProfile()))
                .single();
    }

    // Every profile, also the ones nobody has yet: the dashboard always shows the same tiles.
    private Map<String, Long> byProfile() {
        var counts = new LinkedHashMap<String, Long>();
        for (var profile : PROFILES) {
            counts.put(profile, 0L);
        }
        jdbc.sql("""
                        select p.type, count(*) from profile p join account a on a.id = p.account_id
                        where a.status = 'ACTIVE' group by p.type""")
                .query((rs, n) -> counts.put(rs.getString(1), rs.getLong(2)))
                .list();
        return counts;
    }

    private Events events(Instant now) {
        var today = now.atOffset(ZoneOffset.UTC).toLocalDate();
        return jdbc.sql("""
                        select
                          (select count(*) from event) as total,
                          (select count(*) from event where event_date >= :today) as upcoming,
                          (select count(*) from participant) as entries,
                          (select count(*) from participant_import where created_at >= :weekAgo) as imports,
                          (select coalesce(sum(participants), 0) from participant_import
                             where created_at >= :weekAgo) as imported""")
                .param("today", today)
                .param("weekAgo", Timestamp.from(now.minus(Duration.ofDays(7))))
                .query((rs, n) -> new Events(
                        rs.getLong("total"),
                        rs.getLong("upcoming"),
                        rs.getLong("entries"),
                        rs.getLong("imports"),
                        rs.getLong("imported")))
                .single();
    }

    private Activity activity(Instant now) {
        return jdbc.sql("""
                        select
                          (select count(*) from fight_match where finished_at >= :dayAgo) as finished,
                          (select count(*) from match_event where at >= :dayAgo and not automatic) as actions,
                          (select count(*) from fight_group where created_at >= :dayAgo) as groups_made,
                          (select count(*) from fight_match where status = 'IN_PROGRESS') as in_progress,
                          (select count(*) from fight_match where review_reason is not null) as in_review""")
                .param("dayAgo", Timestamp.from(now.minus(Duration.ofHours(24))))
                .query((rs, n) -> new Activity(
                        rs.getLong("finished"),
                        rs.getLong("actions"),
                        rs.getLong("groups_made"),
                        rs.getLong("in_progress"),
                        rs.getLong("in_review")))
                .single();
    }

    // Spring's own request timers, tagged by outcome: no counter of ours to keep in step.
    private long serverErrors() {
        return meters.find("http.server.requests").tag("outcome", "SERVER_ERROR").timers().stream()
                .mapToLong(Timer::count)
                .sum();
    }
}
