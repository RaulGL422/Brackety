package dev.rgal.brackety.grouping.dto;

import java.time.Instant;
import java.util.UUID;

public record MatOverview(
        UUID id,
        int number,
        String referee,
        int groups,
        int pendingMatches,
        boolean matchInProgress,
        int matchesInReview,
        long remainingSeconds,
        Instant estimatedEnd) {}
