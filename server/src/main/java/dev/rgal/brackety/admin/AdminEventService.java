package dev.rgal.brackety.admin;

import dev.rgal.brackety.admin.dto.AdminEventDtos.Cleared;
import dev.rgal.brackety.admin.dto.AdminEventDtos.EventDetail;
import dev.rgal.brackety.admin.dto.AdminEventDtos.EventPage;
import dev.rgal.brackety.admin.dto.AdminEventDtos.EventRow;
import dev.rgal.brackety.admin.dto.AdminEventDtos.Group;
import dev.rgal.brackety.admin.dto.AdminEventDtos.Mat;
import dev.rgal.brackety.admin.dto.AdminEventDtos.Match;
import dev.rgal.brackety.admin.dto.AdminEventDtos.Member;
import dev.rgal.brackety.admin.dto.AdminEventDtos.PlannedMatch;
import dev.rgal.brackety.admin.dto.AdminEventDtos.Side;
import dev.rgal.brackety.admin.dto.AdminEventDtos.Team;
import dev.rgal.brackety.admin.dto.AdminEventDtos.TeamPerson;
import dev.rgal.brackety.auth.admin.AdminAuditLog;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.StaffNames;
import dev.rgal.brackety.grouping.CompetitionCleanup;
import dev.rgal.brackety.grouping.MatPlanner;
import dev.rgal.brackety.scoreboard.MatchReset;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Events as the superadmin sees them, and what it can undo in them; every change is audited. */
@Service
class AdminEventService {

    static final int MAX_PAGE_SIZE = 100;

    private static final Logger log = LoggerFactory.getLogger(AdminEventService.class);

    // A side is a participant (its name) or a team (its number).
    private static final String MATCHES = """
            select f.id, f.group_id, f.order_index, f.status, f.red_score, f.blue_score,
                   f.review_reason is not null as in_review,
                   rp.first_name || ' ' || rp.last_name as red_name, rt.number as red_team, rt.id as red_team_id,
                   bp.first_name || ' ' || bp.last_name as blue_name, bt.number as blue_team, bt.id as blue_team_id,
                   exists (select 1 from group_member g where g.group_id = f.group_id and g.ghost
                           and (g.participant_id = f.red_participant_id or g.team_id = f.red_team_id)) as red_ghost,
                   exists (select 1 from group_member g where g.group_id = f.group_id and g.ghost
                           and (g.participant_id = f.blue_participant_id or g.team_id = f.blue_team_id)) as blue_ghost
            from fight_match f
            left join participant rp on rp.id = f.red_participant_id
            left join team rt on rt.id = f.red_team_id
            left join participant bp on bp.id = f.blue_participant_id
            left join team bt on bt.id = f.blue_team_id
            where f.event_id = :eventId
            order by f.order_index""";

    private static final String GROUP_MEMBERS = """
            select gm.group_id, gm.ghost, p.first_name || ' ' || p.last_name as name, t.id as team_id,
                   t.number as team_number
            from group_member gm
            join fight_group g on g.id = gm.group_id
            left join participant p on p.id = gm.participant_id
            left join team t on t.id = gm.team_id
            where g.event_id = :eventId
            order by gm.group_id, gm.position""";

    private static final String TEAM_MEMBERS = """
            select tm.team_id, p.first_name || ' ' || p.last_name as name, tm.ghost and not t.ghost as ghost
            from team_member tm
            join team t on t.id = tm.team_id
            join participant p on p.id = tm.participant_id
            where t.event_id = :eventId
            order by tm.team_id, tm.position""";

    private final JdbcClient jdbc;
    private final MatchReset matchReset;
    private final CompetitionCleanup cleanup;
    private final AdminAuditLog audit;
    private final MatPlanner planner;
    private final StaffNames staffNames;

    AdminEventService(
            JdbcClient jdbc,
            MatchReset matchReset,
            CompetitionCleanup cleanup,
            AdminAuditLog audit,
            MatPlanner planner,
            StaffNames staffNames) {
        this.staffNames = staffNames;
        this.jdbc = jdbc;
        this.matchReset = matchReset;
        this.cleanup = cleanup;
        this.audit = audit;
        this.planner = planner;
    }

    /** Newest event first. */
    @Transactional(readOnly = true)
    public EventPage list(int page, int size) {
        if (page < 0 || size < 1 || size > MAX_PAGE_SIZE) {
            throw EventException.invalid("page from 0, size from 1 to " + MAX_PAGE_SIZE + ".");
        }
        var rows = jdbc.sql("""
                        select e.id, e.name, e.event_date, a.email,
                               (select count(*) from mat m where m.event_id = e.id) as mat_count,
                               (select count(*) from participant p where p.event_id = e.id) as entry_count,
                               (select count(*) from fight_group g where g.event_id = e.id) as group_count,
                               (select count(*) from fight_match f where f.event_id = e.id
                                   and f.status = 'FINISHED') as finished_count,
                               (select count(*) from fight_match f where f.event_id = e.id) as match_count
                        from event e join account a on a.id = e.owner_account_id
                        order by e.event_date desc, e.created_at desc
                        limit :size offset :offset""")
                .param("size", size)
                .param("offset", (long) page * size)
                .query((rs, n) -> new EventRow(
                        rs.getObject("id", UUID.class),
                        rs.getString("name"),
                        rs.getObject("event_date", LocalDate.class),
                        rs.getString("email"),
                        rs.getInt("mat_count"),
                        rs.getInt("entry_count"),
                        rs.getInt("group_count"),
                        rs.getInt("finished_count"),
                        rs.getInt("match_count")))
                .list();
        var total = jdbc.sql("select count(*) from event").query(Long.class).single();
        return new EventPage(rows, page, size, total);
    }

    /**
     * Its mats, each with the planned order of its pending matches, and its groups in number order, each with its
     * members (ghost included) and its matches in order.
     */
    @Transactional(readOnly = true)
    public EventDetail detail(UUID eventId) {
        var head = jdbc.sql("""
                        select e.id, e.name, e.event_date, a.email,
                               (select count(*) from participant p where p.event_id = e.id) as entry_count
                        from event e join account a on a.id = e.owner_account_id
                        where e.id = :eventId""")
                .param("eventId", eventId)
                .query((rs, n) -> new EventDetail(
                        rs.getObject("id", UUID.class),
                        rs.getString("name"),
                        rs.getObject("event_date", LocalDate.class),
                        rs.getString("email"),
                        rs.getInt("entry_count"),
                        List.of(),
                        List.of(),
                        List.of()))
                .optional()
                .orElseThrow(EventException::notFound);
        var groups = groups(eventId);
        return new EventDetail(
                head.id(),
                head.name(),
                head.date(),
                head.ownerEmail(),
                head.entries(),
                mats(eventId, groups),
                groups,
                teams(eventId));
    }

    private List<Team> teams(UUID eventId) {
        var members = new HashMap<UUID, List<TeamPerson>>();
        jdbc.sql("""
                        select tm.team_id, tm.participant_id, p.first_name || ' ' || p.last_name as name, tm.ghost
                        from team_member tm
                        join team t on t.id = tm.team_id
                        join participant p on p.id = tm.participant_id
                        where t.event_id = :eventId and not t.ghost
                        order by tm.team_id, tm.position""").param("eventId", eventId).query(rs -> {
            members.computeIfAbsent(rs.getObject("team_id", UUID.class), k -> new ArrayList<>())
                    .add(new TeamPerson(
                            rs.getObject("participant_id", UUID.class), rs.getString("name"), rs.getBoolean("ghost")));
        });
        return jdbc.sql("""
                        select t.id, t.number, c.name as category, g.number as group_number,
                               exists (select 1 from fight_match f where f.group_id = g.id and (f.status <> 'PENDING'
                                 or exists (select 1 from match_event e where e.match_id = f.id))) as started
                        from team t
                        join event_category c on c.id = t.category_id
                        left join group_member gm on gm.team_id = t.id and not gm.ghost
                        left join fight_group g on g.id = gm.group_id
                        where t.event_id = :eventId and not t.ghost
                        order by t.number""")
                .param("eventId", eventId)
                .query((rs, n) -> {
                    var id = rs.getObject("id", UUID.class);
                    return new Team(
                            id,
                            rs.getInt("number"),
                            rs.getString("category"),
                            rs.getObject("group_number", Integer.class),
                            rs.getBoolean("started"),
                            members.getOrDefault(id, List.of()));
                })
                .list();
    }

    private List<Mat> mats(UUID eventId, List<Group> groups) {
        var plan = planner.plan(eventId);
        var labels = staffNames.labels(eventId);
        var groupOf = new HashMap<UUID, Group>();
        var matchById = new HashMap<UUID, Match>();
        for (var g : groups) {
            for (var m : g.matches()) {
                groupOf.put(m.id(), g);
                matchById.put(m.id(), m);
            }
        }
        return jdbc.sql("""
                        select m.id, m.number, m.referee_account_id from mat m
                        where m.event_id = :eventId order by m.number""")
                .param("eventId", eventId)
                .query((rs, n) -> {
                    var id = rs.getObject("id", UUID.class);
                    var planned = plan.getOrDefault(id, List.of()).stream()
                            .map(p -> {
                                var match = matchById.get(p.matchId());
                                var group = groupOf.get(p.matchId());
                                return new PlannedMatch(
                                        p.matchId(),
                                        group.number(),
                                        group.category(),
                                        p.startsAt(),
                                        match.red(),
                                        match.blue());
                            })
                            .toList();
                    var referee = rs.getObject("referee_account_id", UUID.class);
                    return new Mat(id, rs.getInt("number"), referee == null ? null : labels.get(referee), planned);
                })
                .list();
    }

    private List<Group> groups(UUID eventId) {
        var labels = staffNames.labels(eventId);
        var teamMembers = new HashMap<UUID, List<Member>>();
        jdbc.sql(TEAM_MEMBERS).param("eventId", eventId).query(rs -> {
            teamMembers
                    .computeIfAbsent(rs.getObject("team_id", UUID.class), k -> new ArrayList<>())
                    .add(new Member(rs.getString("name"), rs.getBoolean("ghost")));
        });
        var membersByGroup = new HashMap<UUID, List<Side>>();
        jdbc.sql(GROUP_MEMBERS).param("eventId", eventId).query(rs -> {
            membersByGroup
                    .computeIfAbsent(rs.getObject("group_id", UUID.class), k -> new ArrayList<>())
                    .add(side(rs, "", teamMembers));
        });
        var matchesByGroup =
                jdbc.sql(MATCHES).param("eventId", eventId).query((rs, row) -> match(rs, teamMembers)).list().stream()
                        .collect(Collectors.groupingBy(
                                GroupMatch::groupId, Collectors.mapping(GroupMatch::match, Collectors.toList())));
        return jdbc.sql("""
                        select g.id, g.number, c.name as category, m.number as mat_number, g.created_by
                        from fight_group g
                        join event_category c on c.id = g.category_id
                        left join mat m on m.id = g.mat_id
                        where g.event_id = :eventId order by g.number""")
                .param("eventId", eventId)
                .query((rs, n) -> {
                    var id = rs.getObject("id", UUID.class);
                    return new Group(
                            id,
                            rs.getInt("number"),
                            rs.getString("category"),
                            rs.getObject("mat_number", Integer.class),
                            labels.get(rs.getObject("created_by", UUID.class)),
                            membersByGroup.getOrDefault(id, List.of()),
                            matchesByGroup.getOrDefault(id, List.of()));
                })
                .list();
    }

    private record GroupMatch(UUID groupId, Match match) {}

    private static GroupMatch match(ResultSet rs, Map<UUID, List<Member>> teamMembers) throws SQLException {
        return new GroupMatch(
                rs.getObject("group_id", UUID.class),
                new Match(
                        rs.getObject("id", UUID.class),
                        rs.getInt("order_index"),
                        rs.getString("status"),
                        side(rs, "red_", teamMembers),
                        side(rs, "blue_", teamMembers),
                        rs.getInt("red_score"),
                        rs.getInt("blue_score"),
                        rs.getBoolean("in_review")));
    }

    // Columns {prefix}name, {prefix}team (number), {prefix}team_id and {prefix}ghost.
    private static Side side(ResultSet rs, String prefix, Map<UUID, List<Member>> teamMembers) throws SQLException {
        var teamId = rs.getObject(prefix + "team_id", UUID.class);
        return new Side(
                teamId == null ? rs.getString(prefix + "name") : null,
                rs.getObject(prefix + (prefix.isEmpty() ? "team_number" : "team"), Integer.class),
                rs.getBoolean(prefix + "ghost"),
                teamId == null ? List.of() : teamMembers.getOrDefault(teamId, List.of()));
    }

    @Transactional
    public void resetMatch(UUID matchId, String reason) {
        matchReset.reset(matchId);
        audit.matchReset(matchId, reason.strip());
        log.info("Superadmin reset match {}", matchId);
    }

    @Transactional
    public void dissolveGroup(UUID groupId, String reason) {
        cleanup.dissolveGroup(groupId);
        audit.groupDissolved(groupId, reason.strip());
        log.info("Superadmin dissolved group {}", groupId);
    }

    @Transactional
    public Cleared clearCompetition(UUID eventId, String reason) {
        var cleared = cleanup.clearCompetition(eventId);
        audit.competitionCleared(eventId, reason.strip());
        log.info("Superadmin cleared event {}: {} groups, {} teams", eventId, cleared.groups(), cleared.teams());
        return new Cleared(cleared.groups(), cleared.teams());
    }
}
