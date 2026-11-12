package dev.rgal.brackety.eventpackage;

import dev.rgal.brackety.eventpackage.EventResults.ActionEntry;
import dev.rgal.brackety.eventpackage.EventResults.GroupEntry;
import dev.rgal.brackety.eventpackage.EventResults.MatchEntry;
import dev.rgal.brackety.eventpackage.EventResults.MemberEntry;
import dev.rgal.brackety.eventpackage.EventResults.SideEntry;
import dev.rgal.brackety.eventpackage.EventResults.TeamEntry;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Reads and writes an event's results in plain SQL, row for row, so they move between servers as they are (with
 * their times and the scoreboard's actions) without going through the rules that made them.
 */
@Component
class EventResultsTransfer {

    private final JdbcClient jdbc;

    EventResultsTransfer(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    EventResults export(UUID eventId) {
        var persons = map("select id, person_id from participant where event_id = ?", eventId);
        var usernames = new HashMap<UUID, String>();
        jdbc.sql("select id, email from account").query(rs -> {
            usernames.put(uuid(rs, "id"), rs.getString("email"));
        });
        var categoryNames = new HashMap<UUID, String>();
        jdbc.sql("select id, name from event_category where event_id = ?")
                .param(eventId)
                .query(rs -> {
                    categoryNames.put(uuid(rs, "id"), rs.getString("name"));
                });
        var matNumbers = new HashMap<UUID, Integer>();
        jdbc.sql("select id, number from mat where event_id = ?").param(eventId).query(rs -> {
            matNumbers.put(uuid(rs, "id"), rs.getInt("number"));
        });
        var teamNumbers = new HashMap<UUID, Integer>();
        var teamMembers = new HashMap<UUID, List<UUID>>();
        var ghostMembers = new HashMap<UUID, List<UUID>>();
        jdbc.sql("select m.team_id, m.participant_id, m.ghost and not t.ghost as ghost_member from team_member m"
                        + " join team t on t.id = m.team_id where t.event_id = ? order by m.team_id, m.position")
                .param(eventId)
                .query(rs -> {
                    var person = persons.get(uuid(rs, "participant_id"));
                    teamMembers
                            .computeIfAbsent(uuid(rs, "team_id"), k -> new ArrayList<>())
                            .add(person);
                    if (rs.getBoolean("ghost_member")) {
                        ghostMembers
                                .computeIfAbsent(uuid(rs, "team_id"), k -> new ArrayList<>())
                                .add(person);
                    }
                });
        var teams = jdbc.sql("select * from team where event_id = ? order by number")
                .param(eventId)
                .query((rs, i) -> {
                    teamNumbers.put(uuid(rs, "id"), rs.getInt("number"));
                    return new TeamEntry(
                            rs.getInt("number"),
                            categoryNames.get(uuid(rs, "category_id")),
                            rs.getBoolean("ghost"),
                            usernames.get(uuid(rs, "created_by")),
                            instant(rs, "created_at"),
                            teamMembers.getOrDefault(uuid(rs, "id"), List.of()),
                            ghostMembers.getOrDefault(uuid(rs, "id"), List.of()));
                })
                .list();
        var groupMembers = new HashMap<UUID, List<MemberEntry>>();
        jdbc.sql("select m.* from group_member m join fight_group g on g.id = m.group_id"
                        + " where g.event_id = ? order by m.group_id, m.position")
                .param(eventId)
                .query(rs -> {
                    groupMembers
                            .computeIfAbsent(uuid(rs, "group_id"), k -> new ArrayList<>())
                            .add(new MemberEntry(
                                    rs.getInt("position"),
                                    rs.getBoolean("ghost"),
                                    persons.get(uuid(rs, "participant_id")),
                                    teamNumbers.get(uuid(rs, "team_id"))));
                });
        var groupNumbers = new HashMap<UUID, Integer>();
        var groups = jdbc.sql("select * from fight_group where event_id = ? order by number")
                .param(eventId)
                .query((rs, i) -> {
                    groupNumbers.put(uuid(rs, "id"), rs.getInt("number"));
                    return new GroupEntry(
                            rs.getInt("number"),
                            categoryNames.get(uuid(rs, "category_id")),
                            matNumbers.get(uuid(rs, "mat_id")),
                            usernames.get(uuid(rs, "created_by")),
                            instant(rs, "created_at"),
                            groupMembers.getOrDefault(uuid(rs, "id"), List.of()));
                })
                .list();
        var actions = new HashMap<UUID, List<ActionEntry>>();
        var positions = new HashMap<UUID, Integer>();
        jdbc.sql("select e.id, e.position from match_event e join fight_match m on m.id = e.match_id"
                        + " where m.event_id = ?")
                .param(eventId)
                .query(rs -> {
                    positions.put(uuid(rs, "id"), rs.getInt("position"));
                });
        jdbc.sql("select e.* from match_event e join fight_match m on m.id = e.match_id"
                        + " where m.event_id = ? order by e.match_id, e.position")
                .param(eventId)
                .query(rs -> {
                    var target = uuid(rs, "target_event_id");
                    actions.computeIfAbsent(uuid(rs, "match_id"), k -> new ArrayList<>())
                            .add(new ActionEntry(
                                    rs.getInt("position"),
                                    rs.getString("type"),
                                    rs.getString("side"),
                                    rs.getString("reason"),
                                    target == null ? null : positions.get(target),
                                    usernames.get(uuid(rs, "actor_account_id")),
                                    rs.getBoolean("automatic"),
                                    instant(rs, "at"),
                                    rs.getLong("clock_ms")));
                });
        var matches = jdbc
                .sql("select * from fight_match where event_id = ?")
                .param(eventId)
                .query((rs, i) -> new MatchEntry(
                        groupNumbers.get(uuid(rs, "group_id")),
                        rs.getInt("order_index"),
                        matNumbers.get(uuid(rs, "mat_id")),
                        side(rs, "red", persons, teamNumbers),
                        side(rs, "blue", persons, teamNumbers),
                        rs.getString("status"),
                        rs.getInt("red_score"),
                        rs.getInt("blue_score"),
                        instant(rs, "started_at"),
                        instant(rs, "finished_at"),
                        rs.getLong("elapsed_ms"),
                        instant(rs, "running_since"),
                        rs.getString("disqualified_side"),
                        rs.getString("review_reason"),
                        actions.getOrDefault(uuid(rs, "id"), List.of())))
                .list()
                .stream()
                .sorted((a, b) -> a.groupNumber() != b.groupNumber()
                        ? Integer.compare(a.groupNumber(), b.groupNumber())
                        : Integer.compare(a.orderIndex(), b.orderIndex()))
                .toList();
        return new EventResults(teams, groups, matches);
    }

    /**
     * Writes the results into an event with no groups or teams. Everything they name must exist: participants by
     * person id (or its alias: package person id → the one here), categories by name, mats by number. Accounts
     * unknown here are left empty (who did it).
     */
    void write(UUID eventId, EventResults results, Map<UUID, UUID> aliases) {
        var participants = map("select person_id, id from participant where event_id = ?", eventId);
        aliases.forEach((alias, person) -> participants.put(alias, participants.get(person)));
        var categories = new HashMap<String, UUID>();
        jdbc.sql("select id, name from event_category where event_id = ?")
                .param(eventId)
                .query(rs -> {
                    categories.put(rs.getString("name"), uuid(rs, "id"));
                });
        var mats = new HashMap<Integer, UUID>();
        jdbc.sql("select id, number from mat where event_id = ?").param(eventId).query(rs -> {
            mats.put(rs.getInt("number"), uuid(rs, "id"));
        });
        var accounts = new HashMap<String, UUID>();
        jdbc.sql("select id, email from account").query(rs -> {
            accounts.put(rs.getString("email"), uuid(rs, "id"));
        });

        var teams = new HashMap<Integer, UUID>();
        for (var t : results.teams()) {
            var id = UUID.randomUUID();
            teams.put(t.number(), id);
            jdbc.sql("insert into team (id, event_id, category_id, number, ghost, created_by, created_at)"
                            + " values (?, ?, ?, ?, ?, ?, ?)")
                    .params(
                            id,
                            eventId,
                            required(categories, t.categoryName(), "team category"),
                            t.number(),
                            t.ghost(),
                            accounts.get(t.createdBy()),
                            timestamp(t.createdAt()))
                    .update();
            var ghostMembers = t.ghostMemberPersonIds() == null ? List.<UUID>of() : t.ghostMemberPersonIds();
            for (int i = 0; i < t.memberPersonIds().size(); i++) {
                var person = t.memberPersonIds().get(i);
                jdbc.sql("insert into team_member (id, team_id, participant_id, position, ghost)"
                                + " values (?, ?, ?, ?, ?)")
                        .params(
                                UUID.randomUUID(),
                                id,
                                required(participants, person, "team member"),
                                i,
                                t.ghost() || ghostMembers.contains(person))
                        .update();
            }
        }
        var groups = new HashMap<Integer, UUID>();
        for (var g : results.groups()) {
            var id = UUID.randomUUID();
            groups.put(g.number(), id);
            jdbc.sql("insert into fight_group (id, event_id, category_id, mat_id, number, created_by, created_at)"
                            + " values (?, ?, ?, ?, ?, ?, ?)")
                    .params(
                            id,
                            eventId,
                            required(categories, g.categoryName(), "group category"),
                            required(mats, g.matNumber(), "group mat"),
                            g.number(),
                            accounts.get(g.createdBy()),
                            timestamp(g.createdAt()))
                    .update();
            for (var m : g.members()) {
                jdbc.sql("insert into group_member (id, group_id, participant_id, team_id, position, ghost)"
                                + " values (?, ?, ?, ?, ?, ?)")
                        .params(
                                UUID.randomUUID(),
                                id,
                                m.personId() == null ? null : required(participants, m.personId(), "group member"),
                                m.teamNumber() == null ? null : required(teams, m.teamNumber(), "group team"),
                                m.position(),
                                m.ghost())
                        .update();
            }
        }
        for (var m : results.matches()) {
            var id = UUID.randomUUID();
            jdbc.sql("insert into fight_match (id, event_id, group_id, mat_id, order_index, red_participant_id,"
                            + " blue_participant_id, red_team_id, blue_team_id, status, red_score, blue_score,"
                            + " started_at, finished_at, elapsed_ms, running_since, disqualified_side, review_reason)"
                            + " values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
                    .params(
                            id,
                            eventId,
                            required(groups, m.groupNumber(), "match group"),
                            required(mats, m.matNumber(), "match mat"),
                            m.orderIndex(),
                            person(participants, m.red()),
                            person(participants, m.blue()),
                            team(teams, m.red()),
                            team(teams, m.blue()),
                            m.status(),
                            m.redScore(),
                            m.blueScore(),
                            timestamp(m.startedAt()),
                            timestamp(m.finishedAt()),
                            m.elapsedMs(),
                            timestamp(m.runningSince()),
                            m.disqualifiedSide(),
                            m.reviewReason())
                    .update();
            var actionIds = new HashMap<Integer, UUID>();
            for (var a : m.actions()) {
                var actionId = UUID.randomUUID();
                actionIds.put(a.position(), actionId);
                jdbc.sql(
                                "insert into match_event (id, match_id, position, type, side, reason, target_event_id,"
                                        + " actor_account_id, automatic, at, clock_ms) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
                        .params(
                                actionId,
                                id,
                                a.position(),
                                a.type(),
                                a.side(),
                                a.reason(),
                                a.undoesPosition() == null
                                        ? null
                                        : required(actionIds, a.undoesPosition(), "undone action"),
                                accounts.get(a.actor()),
                                a.automatic(),
                                timestamp(a.at()),
                                a.clockMs())
                        .update();
            }
        }
    }

    private Map<UUID, UUID> map(String sql, UUID eventId) {
        var result = new HashMap<UUID, UUID>();
        jdbc.sql(sql).param(eventId).query(rs -> {
            result.put(uuid(rs, 1), uuid(rs, 2));
        });
        return result;
    }

    private static UUID person(Map<UUID, UUID> participants, SideEntry side) {
        return side.personId() == null ? null : required(participants, side.personId(), "match side");
    }

    private static UUID team(Map<Integer, UUID> teams, SideEntry side) {
        return side.teamNumber() == null ? null : required(teams, side.teamNumber(), "match team");
    }

    private static <K> UUID required(Map<K, UUID> ids, K key, String what) {
        var id = ids.get(key);
        if (id == null) {
            throw new InvalidEventPackageException("results: a " + what + " is not in the package");
        }
        return id;
    }

    private static SideEntry side(ResultSet rs, String side, Map<UUID, UUID> persons, Map<UUID, Integer> teams)
            throws SQLException {
        return new SideEntry(persons.get(uuid(rs, side + "_participant_id")), teams.get(uuid(rs, side + "_team_id")));
    }

    private static UUID uuid(ResultSet rs, String column) throws SQLException {
        return rs.getObject(column, UUID.class);
    }

    private static UUID uuid(ResultSet rs, int column) throws SQLException {
        return rs.getObject(column, UUID.class);
    }

    private static Instant instant(ResultSet rs, String column) throws SQLException {
        var value = rs.getTimestamp(column);
        return value == null ? null : value.toInstant();
    }

    private static Timestamp timestamp(Instant instant) {
        return instant == null ? null : Timestamp.from(instant);
    }

    static String summary(EventResults results) {
        return results.teams().size() + " teams, " + results.groups().size() + " groups, "
                + results.matches().size() + " matches, " + results.actionCount() + " actions";
    }
}
