package dev.rgal.brackety.ranking;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.grouping.Competitor;
import dev.rgal.brackety.grouping.Competitors;
import dev.rgal.brackety.grouping.FightGroup;
import dev.rgal.brackety.grouping.GroupMember;
import dev.rgal.brackety.grouping.Match;
import dev.rgal.brackety.participant.Participant;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.stream.Collectors;

/** What is known of the event, loaded once for the sheets ({@link SheetSource}). */
record SheetData(
        Event event,
        List<Participant> participants,
        Map<UUID, Participant> participantsById,
        Map<UUID, String> organizationNames,
        List<EventCategory> categories,
        Map<UUID, String> categoryNames,
        Competitors competitors,
        Map<UUID, Integer> teamNumbers,
        Map<UUID, FightGroup> groups,
        List<GroupMember> members,
        List<Match> matches,
        Map<UUID, Integer> matNumbers,
        List<Mat> mats) {

    /** The clubs of a competitor's members, each once. */
    String clubOf(Competitor c) {
        return c.participantIds().stream()
                .map(id -> organizationNames.get(participantsById.get(id).getOrganizationId()))
                .filter(Objects::nonNull)
                .collect(Collectors.toCollection(LinkedHashSet::new))
                .stream()
                .collect(Collectors.joining(", "));
    }

    int groupNumber(UUID groupId) {
        return groups.get(groupId).getNumber();
    }
}
