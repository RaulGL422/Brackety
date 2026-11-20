package dev.rgal.brackety.event;

import java.util.Arrays;
import java.util.EnumSet;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;

/** Every event endpoint checks the caller's role or permission in that event here, on the server. */
@Service
public class EventAccess {

    private final EventStaffRepository staff;
    private final JdbcClient jdbc;

    EventAccess(EventStaffRepository staff, JdbcClient jdbc) {
        this.staff = staff;
        this.jdbc = jdbc;
    }

    public Set<EventRole> roles(UUID eventId, UUID accountId) {
        return staff.findByEventIdAndAccountId(eventId, accountId).stream()
                .map(EventStaff::getRole)
                .collect(Collectors.toCollection(() -> EnumSet.noneOf(EventRole.class)));
    }

    public void require(UUID eventId, UUID accountId, EventRole... allowed) {
        var roles = roles(eventId, accountId);
        if (roles.isEmpty()) {
            throw EventException.notFound();
        }
        if (Arrays.stream(allowed).noneMatch(roles::contains)) {
            throw EventException.forbidden();
        }
    }

    /** Passes with any of [anyOf]; the club always passes. */
    public void require(UUID eventId, UUID accountId, EventPermission... anyOf) {
        var roles = roles(eventId, accountId);
        if (roles.isEmpty()) {
            throw EventException.notFound();
        }
        var granted = permissions(eventId, accountId, roles);
        if (Arrays.stream(anyOf).noneMatch(granted::contains)) {
            throw EventException.forbidden();
        }
    }

    public boolean has(UUID eventId, UUID accountId, EventPermission permission) {
        return permissions(eventId, accountId, roles(eventId, accountId)).contains(permission);
    }

    /** The club's choice for this person, or the defaults of their roles while it has not chosen. */
    public Set<EventPermission> permissions(UUID eventId, UUID accountId, Set<EventRole> roles) {
        if (roles.isEmpty() || roles.contains(EventRole.CLUB)) {
            return EventPermission.defaults(roles);
        }
        return jdbc.sql("select permissions from event_staff_permissions where event_id = ? and account_id = ?")
                .params(eventId, accountId)
                .query(String.class)
                .optional()
                .map(EventAccess::parse)
                .orElseGet(() -> EventPermission.defaults(roles));
    }

    public void setPermissions(UUID eventId, UUID accountId, Set<EventPermission> permissions) {
        var joined = permissions.stream().map(Enum::name).sorted().collect(Collectors.joining(","));
        jdbc.sql("""
                        insert into event_staff_permissions (event_id, account_id, permissions) values (?, ?, ?)
                        on conflict (event_id, account_id) do update set permissions = excluded.permissions""").params(eventId, accountId, joined).update();
    }

    /** The choices the club made in this event, by account; whoever is missing has their roles' defaults. */
    public Map<UUID, Set<EventPermission>> savedPermissions(UUID eventId) {
        return jdbc
                .sql("select account_id, permissions from event_staff_permissions where event_id = ?")
                .params(eventId)
                .query((rs, row) -> Map.entry(rs.getObject(1, UUID.class), parse(rs.getString(2))))
                .list()
                .stream()
                .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
    }

    /** Back to the defaults: for whoever leaves the event, so returning starts afresh. */
    public void clearPermissions(UUID eventId, UUID accountId) {
        jdbc.sql("delete from event_staff_permissions where event_id = ? and account_id = ?")
                .params(eventId, accountId)
                .update();
    }

    /** A new phase keeps the choices of the one it comes from. */
    public void copyPermissions(UUID fromEventId, UUID toEventId) {
        jdbc.sql("""
                        insert into event_staff_permissions (event_id, account_id, permissions)
                        select ?, account_id, permissions from event_staff_permissions where event_id = ?""").params(toEventId, fromEventId).update();
    }

    private static Set<EventPermission> parse(String joined) {
        var permissions = EnumSet.noneOf(EventPermission.class);
        for (var name : joined.split(",")) {
            if (!name.isBlank()) {
                permissions.add(EventPermission.valueOf(name));
            }
        }
        return permissions;
    }
}
