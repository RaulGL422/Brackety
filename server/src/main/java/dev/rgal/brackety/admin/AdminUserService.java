package dev.rgal.brackety.admin;

import dev.rgal.brackety.admin.dto.AdminUserDtos.UserDetail;
import dev.rgal.brackety.admin.dto.AdminUserDtos.UserPage;
import dev.rgal.brackety.admin.dto.AdminUserDtos.UserRow;
import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.admin.AdminAuditLog;
import dev.rgal.brackety.auth.me.AccountDeletionService;
import dev.rgal.brackety.auth.session.SessionService;
import dev.rgal.brackety.event.EventException;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Accounts as the superadmin sees them: search, suspend and lift it, delete on request (all audited). */
@Service
class AdminUserService {

    private static final Logger log = LoggerFactory.getLogger(AdminUserService.class);

    // The profiles come joined, sorted, in one column.
    private static final String SELECT = """
            select a.id, a.email, a.created_at, a.email_verified, a.status, a.suspended_at is not null as suspended,
                   (select string_agg(p.type, ',' order by p.type) from profile p where p.account_id = a.id)
                       as profiles,
                   (select max(p.organization_name) from profile p where p.account_id = a.id) as organization
            from account a
            """;

    // Part of the email or of the organizer's name; '' matches everyone.
    private static final String SEARCH = """
            where :pattern = '' or lower(a.email) like :pattern escape '\\'
               or exists (select 1 from profile p where p.account_id = a.id
                          and lower(p.organization_name) like :pattern escape '\\')
            """;

    private final JdbcClient jdbc;
    private final AccountRepository accounts;
    private final SessionService sessions;
    private final AccountDeletionService deletion;
    private final AdminAuditLog audit;
    private final Clock clock;

    AdminUserService(
            JdbcClient jdbc,
            AccountRepository accounts,
            SessionService sessions,
            AccountDeletionService deletion,
            AdminAuditLog audit,
            Clock clock) {
        this.jdbc = jdbc;
        this.accounts = accounts;
        this.sessions = sessions;
        this.deletion = deletion;
        this.audit = audit;
        this.clock = clock;
    }

    /** Newest first; {@code query} (empty = all) is part of the email or of the organization's name. */
    @Transactional(readOnly = true)
    public UserPage list(String query, int page, int size) {
        if (page < 0 || size < 1 || size > AdminEventService.MAX_PAGE_SIZE) {
            throw EventException.invalid("page from 0, size from 1 to " + AdminEventService.MAX_PAGE_SIZE + ".");
        }
        var pattern = pattern(query);
        var rows = jdbc.sql(SELECT + SEARCH + " order by a.created_at desc limit :size offset :offset")
                .param("pattern", pattern)
                .param("size", size)
                .param("offset", (long) page * size)
                .query(AdminUserService::row)
                .list();
        var total = jdbc.sql("select count(*) from account a " + SEARCH)
                .param("pattern", pattern)
                .query(Long.class)
                .single();
        return new UserPage(rows, page, size, total);
    }

    @Transactional(readOnly = true)
    public UserDetail detail(UUID accountId) {
        var row = jdbc.sql(SELECT + "where a.id = :id")
                .param("id", accountId)
                .query(AdminUserService::row)
                .optional()
                .orElseThrow(AuthException::notFound);
        var account = accounts.findById(accountId).orElseThrow(AuthException::notFound);
        var methods = new ArrayList<String>();
        if (account.hasPassword()) {
            methods.add("PASSWORD");
        }
        methods.addAll(jdbc.sql("select provider from identity where account_id = ? order by provider")
                .param(accountId)
                .query(String.class)
                .list());
        return new UserDetail(
                row,
                methods,
                count("select count(*) from event where owner_account_id = ?", accountId),
                count("select count(distinct event_id) from event_staff where account_id = ?", accountId),
                lastSignIn(accountId),
                account.getSuspendedAt(),
                account.deletesOn(clock.getZone()));
    }

    /** Its sessions close at once and no new one starts until it is lifted. Idempotent. */
    @Transactional
    public void suspend(UUID accountId, String reason) {
        var account = activeLocked(accountId);
        if (account.isSuspended()) {
            return;
        }
        account.suspend(clock.instant());
        sessions.closeAll(account);
        audit.userSuspended(accountId, reason.strip());
        log.info("Superadmin suspended account {}", accountId);
    }

    @Transactional
    public void unsuspend(UUID accountId, String reason) {
        var account = activeLocked(accountId);
        if (!account.isSuspended()) {
            return;
        }
        account.unsuspend(clock.instant());
        audit.userUnsuspended(accountId, reason.strip());
        log.info("Superadmin lifted the suspension of account {}", accountId);
    }

    /**
     * The same deletion as the owner's own (docs/modulos/auth.md): signed out, purged for good after the grace, and
     * the owner is emailed and can still restore it. An owner of events is refused (409 OWNS_EVENTS).
     */
    @Transactional
    public LocalDate delete(UUID accountId, String reason) {
        var deletesOn = deletion.schedule(activeLocked(accountId)).deletesOn();
        audit.userDeleted(accountId, reason.strip());
        log.info("Superadmin deleted account {}", accountId);
        return deletesOn;
    }

    private Account activeLocked(UUID accountId) {
        return accounts.lockById(accountId).filter(Account::isActive).orElseThrow(AuthException::notFound);
    }

    // Null for an account that never signed in.
    private Instant lastSignIn(UUID accountId) {
        var newest = jdbc.sql("select max(created_at) from refresh_token where account_id = ?")
                .param(accountId)
                .query((rs, n) -> rs.getTimestamp(1))
                .list()
                .getFirst();
        return newest == null ? null : newest.toInstant();
    }

    private int count(String sql, UUID accountId) {
        return jdbc.sql(sql).param(accountId).query(Integer.class).single();
    }

    // Lower case and with LIKE's wildcards escaped: "50%" looks for those three characters.
    private static String pattern(String query) {
        var q = query == null ? "" : query.strip().toLowerCase(Locale.ROOT);
        if (q.isEmpty()) {
            return "";
        }
        return "%" + q.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%";
    }

    private static UserRow row(ResultSet rs, int n) throws SQLException {
        var profiles = rs.getString("profiles");
        return new UserRow(
                rs.getObject("id", UUID.class),
                rs.getString("email"),
                rs.getTimestamp("created_at").toInstant(),
                rs.getBoolean("email_verified"),
                rs.getString("status"),
                rs.getBoolean("suspended"),
                profiles == null ? List.of() : Arrays.asList(profiles.split(",")),
                rs.getString("organization"));
    }
}
