package dev.rgal.debug;

import dev.rgal.brackety.auth.admin.AdminAuditLog;
import dev.rgal.brackety.event.EventException;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.transaction.support.TransactionOperations;

/**
 * Named copies of the debug database (docs/modulos/entornos.md), to repeat a test without setting it up again. Each
 * one is a schema {@code snapshot_<name>} in the same database: the API has no {@code pg_dump}, and loading a
 * scenario empties only the app's tables, so the copies survive it.
 */
public class DebugSnapshots {

    private static final Logger log = LoggerFactory.getLogger(DebugSnapshots.class);
    private static final String PREFIX = "snapshot_";
    private static final Pattern NAME = Pattern.compile("[a-z0-9_]{1,40}");

    /** {@code scenario}: the one loaded when it was saved, or null. */
    public record Snapshot(String name, Instant savedAt, String scenario) {}

    private final JdbcClient jdbc;
    private final TransactionOperations transactions;
    private final AdminAuditLog audit;
    private final Clock clock;

    DebugSnapshots(JdbcClient jdbc, TransactionOperations transactions, AdminAuditLog audit, Clock clock) {
        this.jdbc = jdbc;
        this.transactions = transactions;
        this.audit = audit;
        this.clock = clock;
    }

    public List<Snapshot> list() {
        return jdbc.sql("select substring(nspname from 10), obj_description(oid, 'pg_namespace') from pg_namespace"
                        + " where nspname like 'snapshot\\_%' order by nspname")
                .query((rs, i) -> snapshot(rs.getString(1), rs.getString(2)))
                .list();
    }

    /** A copy of every table of the app, under [name]; one with the same name is replaced. */
    public Snapshot save(String name, String scenario) {
        var schema = schema(name);
        var savedAt = clock.instant();
        transactions.executeWithoutResult(status -> {
            jdbc.sql("drop schema if exists " + schema + " cascade").update();
            jdbc.sql("create schema " + schema).update();
            for (var table : DebugData.appTables(jdbc)) {
                jdbc.sql("create table " + schema + "." + table + " as table " + table)
                        .update();
            }
            var comment = String.join(";", version(), savedAt.toString(), scenario == null ? "" : scenario);
            jdbc.sql("comment on schema " + schema + " is '" + comment.replace("'", "''") + "'")
                    .update();
        });
        audit.debug(name, "copy saved");
        log.warn("Debug copy '{}' saved", name);
        return new Snapshot(name, savedAt, scenario);
    }

    /** Back to the copy: the app's tables emptied and filled from it. Its scenario, if any. */
    public Snapshot restore(String name) {
        var schema = schema(name);
        var snapshot =
                list().stream().filter(s -> s.name().equals(name)).findFirst().orElseThrow(EventException::notFound);
        var saved = jdbc.sql("select obj_description(oid, 'pg_namespace') from pg_namespace where nspname = ?")
                .param(schema)
                .query(String.class)
                .single();
        if (!saved.split(";", -1)[0].equals(version())) {
            throw EventException.conflict(
                    "SNAPSHOT_OTHER_VERSION", "Saved with another version of the database: its tables do not match.");
        }
        transactions.executeWithoutResult(status -> {
            var tables = DebugData.appTables(jdbc);
            jdbc.sql("truncate table " + String.join(", ", tables) + " cascade").update();
            // Parents before children, so every foreign key finds its row.
            for (var table : parentsFirst(tables)) {
                jdbc.sql("insert into " + table + " select * from " + schema + "." + table)
                        .update();
            }
        });
        audit.debug(name, "copy restored");
        log.warn("Debug copy '{}' restored", name);
        return snapshot;
    }

    public void delete(String name) {
        var schema = schema(name);
        if (list().stream().noneMatch(s -> s.name().equals(name))) {
            throw EventException.notFound();
        }
        jdbc.sql("drop schema " + schema + " cascade").update();
        audit.debug(name, "copy deleted");
    }

    private List<String> parentsFirst(List<String> tables) {
        var parents = new HashMap<String, Set<String>>();
        tables.forEach(t -> parents.put(t, new HashSet<>()));
        jdbc
                .sql("select quote_ident(child.relname), quote_ident(parent.relname) from pg_constraint c"
                        + " join pg_class child on child.oid = c.conrelid join pg_class parent on parent.oid = c.confrelid"
                        + " where c.contype = 'f' and c.connamespace = current_schema()::regnamespace")
                .query((rs, i) -> Map.entry(rs.getString(1), rs.getString(2)))
                .list()
                .stream()
                // A row pointing at its own table is checked at the end of the statement.
                .filter(e -> !e.getKey().equals(e.getValue()) && parents.containsKey(e.getKey()))
                .forEach(e -> parents.get(e.getKey()).add(e.getValue()));
        var ordered = new LinkedHashSet<String>();
        var pending = new ArrayDeque<>(tables);
        while (!pending.isEmpty()) {
            var progress = false;
            for (var i = pending.size(); i > 0; i--) {
                var table = pending.poll();
                if (ordered.containsAll(parents.get(table))) {
                    ordered.add(table);
                    progress = true;
                } else {
                    pending.add(table);
                }
            }
            if (!progress) {
                throw new IllegalStateException("Foreign keys in a cycle: " + pending);
            }
        }
        return new ArrayList<>(ordered);
    }

    private String version() {
        return jdbc.sql("select version from flyway_schema_history where success order by installed_rank desc limit 1")
                .query(String.class)
                .single();
    }

    private static String schema(String name) {
        if (name == null || !NAME.matcher(name).matches()) {
            throw EventException.invalid("A copy's name: lowercase letters, digits and _ (up to 40).");
        }
        return PREFIX + name;
    }

    private static Snapshot snapshot(String name, String comment) {
        var parts = (comment == null ? ";;" : comment).split(";", -1);
        return new Snapshot(
                name,
                parts.length > 1 && !parts[1].isEmpty() ? Instant.parse(parts[1]) : null,
                parts.length > 2 && !parts[2].isEmpty() ? parts[2] : null);
    }
}
