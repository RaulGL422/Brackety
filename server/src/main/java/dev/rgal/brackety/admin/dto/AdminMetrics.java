package dev.rgal.brackety.admin.dto;

import java.time.Instant;
import java.util.Map;

/**
 * The superadmin's dashboard (docs/modulos/superadmin-reportes.md): counts read at {@code at}. "24 h" and
 * "7 days" count back from then; the server block is since its last start (in memory, not stored).
 */
public record AdminMetrics(Instant at, Users users, Events events, Activity activity, Server server) {

    /** {@code byProfile}: active accounts with each profile (an account can have several). */
    public record Users(
            long active,
            long unverified,
            long newLast7Days,
            long pendingDeletion,
            long organizersPending,
            long activeSessions,
            long activeLocks,
            Map<String, Long> byProfile) {}

    /** {@code imported...}: entries from lists read with Claude. */
    public record Events(long total, long upcoming, long entries, long importsLast7Days, long importedLast7Days) {}

    /** The last 24 h, and right now ({@code inProgress}, {@code inReview}). */
    public record Activity(
            long matchesFinished24h,
            long scoreboardActions24h,
            long groupsCreated24h,
            long matchesInProgress,
            long matchesInReview) {}

    /** {@code serverErrors}: API answers 5xx since {@code startedAt}. */
    public record Server(Instant startedAt, long serverErrors) {}
}
