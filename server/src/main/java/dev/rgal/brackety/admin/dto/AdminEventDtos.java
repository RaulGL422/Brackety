package dev.rgal.brackety.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.Instant;
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

    /**
     * {@code referee}: the referee ("Juan Pérez (arbitro1)", or the sign-in alone), null when the mat has none.
     * {@code plan}: its
     * pending matches in the order the referee would be offered them if everything goes as planned.
     */
    public record Mat(UUID id, int number, String referee, List<PlannedMatch> plan) {}

    /** {@code startsAt}: estimated, with every match at its full time plus the changeover. */
    public record PlannedMatch(UUID matchId, int groupNumber, String category, Instant startsAt, Side red, Side blue) {}

    /**
     * {@code members}: who is in the group, in order, the ghost included (marked). {@code createdBy}: who made it
     * ("Ana López (ayudante1)", or the sign-in alone), null if that account is gone.
     */
    public record Group(
            UUID id,
            int number,
            String category,
            Integer matNumber,
            String createdBy,
            List<Side> members,
            List<Match> matches) {}

    /** {@code status}: PENDING, IN_PROGRESS or FINISHED. */
    public record Match(
            UUID id, int order, String status, Side red, Side blue, int redScore, int blueScore, boolean inReview) {}

    /**
     * A participant's name, or a team's number ({@code name} null) with its {@code members}. {@code ghost}: fights in
     * this group but does not score.
     */
    public record Side(String name, Integer teamNumber, boolean ghost, List<Member> members) {}

    /** A team member; {@code ghost}: fills the team in but does not score for it. */
    public record Member(String name, boolean ghost) {}

    /** Every event operation says why; it goes to the audit. */
    public record ReasonRequest(@NotBlank @Size(max = 300) String reason) {}

    public record Cleared(int groups, int teams) {}
}
