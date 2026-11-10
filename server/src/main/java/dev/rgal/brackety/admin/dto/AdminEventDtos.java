package dev.rgal.brackety.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** What the superadmin sees of events (docs/modulos/superadmin-reportes.md). */
public final class AdminEventDtos {

    private AdminEventDtos() {}

    public record EventPage(List<EventRow> items, int page, int size, long total) {}

    /** {@code matchesFinished} of {@code matches}: how far the competition has gone. */
    public record EventRow(
            UUID id,
            String name,
            LocalDate date,
            String ownerEmail,
            int mats,
            int entries,
            int groups,
            int matchesFinished,
            int matches) {}

    public record EventDetail(
            UUID id, String name, LocalDate date, String ownerEmail, int entries, List<Mat> mats, List<Group> groups) {}

    /** {@code referee}: the referee's sign-in (email or username), null when the mat has none. */
    public record Mat(UUID id, int number, String referee) {}

    public record Group(UUID id, int number, String category, int matNumber, List<Match> matches) {}

    /** {@code status}: PENDING, IN_PROGRESS or FINISHED. */
    public record Match(
            UUID id, int order, String status, Side red, Side blue, int redScore, int blueScore, boolean inReview) {}

    /** A participant's name, or a team's number ({@code name} null). */
    public record Side(String name, Integer teamNumber) {}

    /** Every event operation says why; it goes to the audit. */
    public record ReasonRequest(@NotBlank @Size(max = 300) String reason) {}

    public record Cleared(int groups, int teams) {}
}
