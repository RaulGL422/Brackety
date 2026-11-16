package dev.rgal.brackety.grouping.dto;

import java.time.Instant;
import java.util.UUID;

/**
 * {@code disabledAt}: out of use since then, null while in use; {@code disabledReferee}: the referee it had, who
 * gets it back on enabling it.
 */
public record MatOverview(
        UUID id,
        int number,
        String referee,
        Instant disabledAt,
        String disabledReferee,
        int groups,
        int pendingMatches,
        boolean matchInProgress,
        int matchesInReview,
        long remainingSeconds,
        Instant estimatedEnd) {}
