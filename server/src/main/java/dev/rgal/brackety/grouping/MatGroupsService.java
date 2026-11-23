package dev.rgal.brackety.grouping;

import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventPermission;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.event.StaffNames;
import dev.rgal.brackety.grouping.dto.MatGroups;
import dev.rgal.brackety.grouping.dto.MatGroups.GroupCard;
import dev.rgal.brackety.grouping.dto.MatGroups.Member;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** The groups of every mat with who is in them, to see and move them at a glance (GR-4). */
@Service
class MatGroupsService {

    private final MatRepository mats;
    private final FightGroupRepository groups;
    private final GroupMemberRepository members;
    private final MatchRepository matches;
    private final EventCategoryRepository categories;
    private final CompetitorDirectory directory;
    private final StaffNames staffNames;
    private final EventAccess access;

    MatGroupsService(
            MatRepository mats,
            FightGroupRepository groups,
            GroupMemberRepository members,
            MatchRepository matches,
            EventCategoryRepository categories,
            CompetitorDirectory directory,
            StaffNames staffNames,
            EventAccess access) {
        this.mats = mats;
        this.groups = groups;
        this.members = members;
        this.matches = matches;
        this.categories = categories;
        this.directory = directory;
        this.staffNames = staffNames;
        this.access = access;
    }

    /** Groups of teams have no mat (their matches go to the free mats), so they are not here. */
    @Transactional(readOnly = true)
    List<MatGroups> list(UUID eventId, UUID accountId) {
        access.require(
                eventId,
                accountId,
                EventPermission.CONTROL,
                EventPermission.MOVE_GROUPS,
                EventPermission.VIEW,
                EventPermission.REVIEWS,
                EventPermission.GROUPS);
        var cards = cards(eventId);
        var referees = staffNames.labels(eventId);
        return mats.findByEventIdOrderByNumber(eventId).stream()
                .map(mat -> {
                    var onMat = cards.getOrDefault(mat.getId(), List.of());
                    var open =
                            onMat.stream().filter(c -> c.played() < c.matches()).toList();
                    return new MatGroups(
                            mat.getId(),
                            mat.getNumber(),
                            referees.get(mat.getRefereeAccountId()),
                            mat.isDisabled(),
                            onMat.size() - open.size(),
                            open);
                })
                .toList();
    }

    // Every group with a mat, by mat, in group number order.
    private Map<UUID, List<GroupCard>> cards(UUID eventId) {
        var withMat = groups.findByEventId(eventId).stream()
                .filter(g -> g.getMatId() != null)
                .sorted(Comparator.comparingInt(FightGroup::getNumber))
                .toList();
        var categoryNames = categories.findByEventIdOrderByMinAge(eventId).stream()
                .collect(Collectors.toMap(EventCategory::getId, EventCategory::getName));
        var competitors = directory.of(eventId);
        var membersByGroup =
                members
                        .findByGroupIdInOrderByPosition(
                                withMat.stream().map(FightGroup::getId).toList())
                        .stream()
                        .collect(Collectors.groupingBy(GroupMember::getGroupId));
        var matchesByGroup = matches.findByEventId(eventId).stream().collect(Collectors.groupingBy(Match::getGroupId));
        return withMat.stream()
                .collect(Collectors.groupingBy(
                        FightGroup::getMatId,
                        Collectors.mapping(
                                g -> card(
                                        g,
                                        categoryNames.get(g.getCategoryId()),
                                        membersByGroup.getOrDefault(g.getId(), List.of()).stream()
                                                .map(m ->
                                                        new Member(competitors.name(m.getCompetitorId()), m.isGhost()))
                                                .toList(),
                                        matchesByGroup.getOrDefault(g.getId(), List.of())),
                                Collectors.toList())));
    }

    private static GroupCard card(FightGroup group, String categoryName, List<Member> members, List<Match> own) {
        return new GroupCard(
                group.getId(),
                group.getNumber(),
                categoryName,
                members,
                (int) own.stream()
                        .filter(m -> m.getStatus() == Match.Status.FINISHED)
                        .count(),
                own.size(),
                own.stream().anyMatch(m -> m.getStatus() == Match.Status.IN_PROGRESS));
    }
}
