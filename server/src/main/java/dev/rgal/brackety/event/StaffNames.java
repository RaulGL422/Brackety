package dev.rgal.brackety.event;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * The person behind each staff account of an event (the hall's accounts are generic: arbitro1, ayudante2…), and the
 * label shown for an account everywhere: "Juan Pérez (arbitro1)", or just the sign-in without a name.
 */
@Component
public class StaffNames {

    private final JdbcClient jdbc;
    private final EventAccess access;

    StaffNames(JdbcClient jdbc, EventAccess access) {
        this.jdbc = jdbc;
        this.access = access;
    }

    /** Account id → person's name, for the accounts that have one in this event. */
    @Transactional(readOnly = true)
    public Map<UUID, String> names(UUID eventId) {
        var result = new HashMap<UUID, String>();
        jdbc.sql("select account_id, name from event_staff_name where event_id = ?")
                .param(eventId)
                .query(rs -> {
                    result.put(rs.getObject("account_id", UUID.class), rs.getString("name"));
                });
        return result;
    }

    /** Account id → label, for every staff account of the event (and any account that made something in it). */
    @Transactional(readOnly = true)
    public Map<UUID, String> labels(UUID eventId) {
        var result = new HashMap<UUID, String>();
        jdbc.sql("""
                        select a.id, a.email, n.name from account a
                        left join event_staff_name n on n.account_id = a.id and n.event_id = :eventId
                        where a.id in (select account_id from event_staff where event_id = :eventId)
                           or a.id in (select created_by from fight_group where event_id = :eventId)""").param("eventId", eventId).query(rs -> {
            result.put(rs.getObject("id", UUID.class), label(rs.getString("name"), rs.getString("email")));
        });
        return result;
    }

    public static String label(String name, String signIn) {
        return name == null ? signIn : name + " (" + signIn + ")";
    }

    /** By the club. A blank {@code name} removes it. Only for accounts on the event's staff. */
    @Transactional
    public void set(UUID eventId, UUID accountId, UUID staffAccountId, String name) {
        access.require(eventId, accountId, EventRole.CLUB);
        if (access.roles(eventId, staffAccountId).isEmpty()) {
            throw EventException.notFound();
        }
        put(eventId, staffAccountId, name);
    }

    /** Without access checks: the event package loader and {@link #set}. */
    public void put(UUID eventId, UUID staffAccountId, String name) {
        jdbc.sql("delete from event_staff_name where event_id = ? and account_id = ?")
                .params(eventId, staffAccountId)
                .update();
        if (name != null && !name.isBlank()) {
            jdbc.sql("insert into event_staff_name (event_id, account_id, name) values (?, ?, ?)")
                    .params(eventId, staffAccountId, name.strip())
                    .update();
        }
    }
}
