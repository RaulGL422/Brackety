package dev.rgal.debug;

import dev.rgal.brackety.auth.admin.AdminAuditLog;
import dev.rgal.brackety.devdata.Scenario;
import dev.rgal.brackety.devdata.ScenarioContext;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.transaction.support.TransactionOperations;

/**
 * Loads a scenario on the running debug server: empties every table but the migration history, then seeds it, as
 * a local start does. Everything goes, sessions included.
 */
public class DebugData {

    private static final Logger log = LoggerFactory.getLogger(DebugData.class);

    /** {@code scenario}: the last one loaded since the server started, or null. */
    public record Status(String scenario, LocalDate today, boolean simulated) {}

    public record ScenarioInfo(String name, String description) {}

    private final List<Scenario> scenarios;
    private final DebugClock clock;
    private final JdbcClient jdbc;
    private final TransactionOperations transactions;
    private final AdminAuditLog audit;
    private final DebugSnapshots snapshots;
    private volatile String loaded;

    DebugData(
            List<Scenario> scenarios,
            DebugClock clock,
            JdbcClient jdbc,
            TransactionOperations transactions,
            AdminAuditLog audit,
            DebugSnapshots snapshots) {
        this.snapshots = snapshots;
        this.scenarios =
                scenarios.stream().sorted(Comparator.comparing(Scenario::name)).toList();
        this.clock = clock;
        this.jdbc = jdbc;
        this.transactions = transactions;
        this.audit = audit;
    }

    public List<ScenarioInfo> scenarios() {
        return scenarios.stream()
                .map(s -> new ScenarioInfo(s.name(), s.description()))
                .toList();
    }

    public Status status() {
        return new Status(loaded, LocalDate.now(clock), clock.isSimulated());
    }

    public Optional<Scenario> find(String name) {
        return scenarios.stream().filter(s -> s.name().equals(name)).findFirst();
    }

    /** {@code today}: the simulated day to seed it on, or null for the real one. */
    public Status load(Scenario scenario, LocalDate today) {
        clock.moveTo(today);
        transactions.executeWithoutResult(status -> {
            jdbc.sql("truncate table " + String.join(", ", appTables(jdbc)) + " cascade")
                    .update();
            scenario.seed(new ScenarioContext(clock));
        });
        loaded = scenario.name();
        // After the wipe, so the audit keeps it.
        audit.debug(scenario.name(), "scenario loaded, today " + LocalDate.now(clock));
        log.warn("Debug data wiped and scenario '{}' loaded, today is {}", scenario.name(), LocalDate.now(clock));
        return status();
    }

    /** The app's tables, quoted: every one of the current schema but the migration history. */
    static List<String> appTables(JdbcClient jdbc) {
        return jdbc.sql("select quote_ident(tablename) from pg_tables where schemaname = current_schema()"
                        + " and tablename <> 'flyway_schema_history' order by tablename")
                .query(String.class)
                .list();
    }

    public List<DebugSnapshots.Snapshot> snapshots() {
        return snapshots.list();
    }

    /** Saves what there is now, with the scenario it came from. */
    public DebugSnapshots.Snapshot save(String name) {
        return snapshots.save(name, loaded);
    }

    public Status restore(String name) {
        loaded = snapshots.restore(name).scenario();
        return status();
    }

    public void deleteSnapshot(String name) {
        snapshots.delete(name);
    }

    public Status moveClock(LocalDate today) {
        clock.moveTo(today);
        audit.debug("clock", today == null ? "back to the real day" : "moved to " + today);
        return status();
    }
}
