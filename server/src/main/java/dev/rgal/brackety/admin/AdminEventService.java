package dev.rgal.brackety.admin;

import dev.rgal.brackety.admin.dto.AdminEventDtos.Cleared;
import dev.rgal.brackety.admin.dto.AdminEventDtos.EventDetail;
import dev.rgal.brackety.admin.dto.AdminEventDtos.EventPage;
import dev.rgal.brackety.admin.dto.AdminEventDtos.EventRow;
import dev.rgal.brackety.admin.dto.AdminEventDtos.Group;
import dev.rgal.brackety.admin.dto.AdminEventDtos.Mat;
import dev.rgal.brackety.admin.dto.AdminEventDtos.Match;
import dev.rgal.brackety.admin.dto.AdminEventDtos.Side;
import dev.rgal.brackety.auth.admin.AdminAuditLog;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.grouping.CompetitionCleanup;
import dev.rgal.brackety.scoreboard.MatchReset;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
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
                   rp.first_name || ' ' || rp.last_name as red_name, rt.number as red_team,
                   bp.first_name || ' ' || bp.last_name as blue_name, bt.number as blue_team
            from fight_match f
            left join participant rp on rp.id = f.red_participant_id
            left join team rt on rt.id = f.red_team_id
            left join participant bp on bp.id = f.blue_participant_id
            left join team bt on bt.id = f.blue_team_id
            where f.event_id = :eventId
            order by f.order_index""";

    private final JdbcClient jdbc;
    private final MatchReset matchReset;
    private final CompetitionCleanup cleanup;
    private final AdminAuditLog audit;

    AdminEventService(JdbcClient jdbc, MatchReset matchReset, CompetitionCleanup cleanup, AdminAuditLog audit) {
        this.jdbc = jdbc;
        this.matchReset = matchReset;
        this.cleanup = cleanup;
        this.audit = audit;
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

    /** Its mats and its groups in number order, each group with its matches in order. */
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
                        List.of()))
                .optional()
                .orElseThrow(EventException::notFound);
        return new EventDetail(
                head.id(), head.name(), head.date(), head.ownerEmail(), head.entries(), mats(eventId), groups(eventId));
    }

    private List<Mat> mats(UUID eventId) {
        return jdbc.sql("""
                        select m.id, m.number, a.email from mat m
                        left join account a on a.id = m.referee_account_id
                        where m.event_id = :eventId order by m.number""")
                .param("eventId", eventId)
                .query((rs, n) -> new Mat(rs.getObject("id", UUID.class), rs.getInt("number"), rs.getString("email")))
                .list();
    }

    private List<Group> groups(UUID eventId) {
        var matchesByGroup = jdbc.sql(MATCHES).param("eventId", eventId).query(AdminEventService::match).list().stream()
                .collect(Collectors.groupingBy(
                        GroupMatch::groupId, Collectors.mapping(GroupMatch::match, Collectors.toList())));
        return jdbc.sql("""
                        select g.id, g.number, c.name as category, m.number as mat_number
                        from fight_group g
                        join event_category c on c.id = g.category_id
                        join mat m on m.id = g.mat_id
                        where g.event_id = :eventId order by g.number""")
                .param("eventId", eventId)
                .query((rs, n) -> {
                    var id = rs.getObject("id", UUID.class);
                    return new Group(
                            id,
                            rs.getInt("number"),
                            rs.getString("category"),
                            rs.getInt("mat_number"),
                            matchesByGroup.getOrDefault(id, List.of()));
                })
                .list();
    }

    private record GroupMatch(UUID groupId, Match match) {}

    private static GroupMatch match(ResultSet rs, int row) throws SQLException {
        return new GroupMatch(
                rs.getObject("group_id", UUID.class),
                new Match(
                        rs.getObject("id", UUID.class),
                        rs.getInt("order_index"),
                        rs.getString("status"),
                        new Side(rs.getString("red_name"), rs.getObject("red_team", Integer.class)),
                        new Side(rs.getString("blue_name"), rs.getObject("blue_team", Integer.class)),
                        rs.getInt("red_score"),
                        rs.getInt("blue_score"),
                        rs.getBoolean("in_review")));
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
