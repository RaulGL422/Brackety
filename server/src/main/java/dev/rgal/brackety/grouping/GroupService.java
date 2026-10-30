package dev.rgal.brackety.grouping;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.grouping.dto.CategoryParticipant;
import dev.rgal.brackety.grouping.dto.CategorySummary;
import dev.rgal.brackety.grouping.dto.CreateGroupsRequest;
import dev.rgal.brackety.grouping.dto.CreateGroupsRequest.GroupRequest;
import dev.rgal.brackety.grouping.dto.CreateGroupsResponse;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.time.Clock;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class GroupService {

    private final FightGroupRepository groups;
    private final GroupMemberRepository members;
    private final MatchRepository matches;
    private final ParticipantRepository participants;
    private final EventCategoryRepository categories;
    private final MatRepository mats;
    private final EventService events;
    private final EventAccess access;
    private final MatSchedule schedule;
    private final Clock clock;

    GroupService(
            FightGroupRepository groups,
            GroupMemberRepository members,
            MatchRepository matches,
            ParticipantRepository participants,
            EventCategoryRepository categories,
            MatRepository mats,
            EventService events,
            EventAccess access,
            MatSchedule schedule,
            Clock clock) {
        this.groups = groups;
        this.members = members;
        this.matches = matches;
        this.participants = participants;
        this.categories = categories;
        this.mats = mats;
        this.events = events;
        this.access = access;
        this.schedule = schedule;
        this.clock = clock;
    }

    /** Categories with participants, youngest first. */
    @Transactional(readOnly = true)
    List<CategorySummary> categories(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB, EventRole.GROUPER);
        var event = events.get(eventId);
        var grouped = groupedIds(eventId);
        var all = participants.findByEventIdOrderByFirstNameAscLastNameAsc(eventId);
        return categories.findByEventIdOrderByMinAge(eventId).stream()
                .map(c -> {
                    var inCategory =
                            all.stream().filter(p -> inCategory(event, c, p)).toList();
                    return new CategorySummary(
                            c.getId(), c.getName(), c.getMinAge(), c.getMaxAge(), inCategory.size(), (int)
                                    inCategory.stream()
                                            .filter(p -> grouped.containsKey(p.getId()))
                                            .count());
                })
                .filter(c -> c.participants() > 0)
                .toList();
    }

    /** A category's participants by name; those already in a group say which one and where. */
    @Transactional(readOnly = true)
    List<CategoryParticipant> categoryParticipants(UUID eventId, UUID categoryId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB, EventRole.GROUPER);
        var event = events.get(eventId);
        var category = category(eventId, categoryId);
        var grouped = groupedIds(eventId);
        var matNumbers =
                mats.findByEventIdOrderByNumber(eventId).stream().collect(Collectors.toMap(Mat::getId, Mat::getNumber));
        return participants.findByEventIdOrderByFirstNameAscLastNameAsc(eventId).stream()
                .filter(p -> inCategory(event, category, p))
                .map(p -> {
                    var group = grouped.get(p.getId());
                    return new CategoryParticipant(
                            p.getId(),
                            p.getFirstName(),
                            p.getLastName(),
                            p.getHeightCm(),
                            event.ageOf(p.getBirthDate()),
                            group == null ? null : group.getNumber(),
                            group == null ? null : matNumbers.get(group.getMatId()));
                })
                .toList();
    }

    @Transactional
    CreateGroupsResponse create(UUID eventId, UUID accountId, CreateGroupsRequest request) {
        access.require(eventId, accountId, EventRole.CLUB, EventRole.GROUPER);
        var event = events.lock(eventId);
        if (request.groups().size() > event.getMaxGroupsPerMat()) {
            throw EventException.invalid("At most " + event.getMaxGroupsPerMat() + " groups go to a mat at once.");
        }
        var category = category(eventId, request.categoryId());
        var real = new ArrayList<UUID>();
        var involved = new HashSet<UUID>();
        for (var group : request.groups()) {
            checkShape(group);
            real.addAll(group.participantIds());
            involved.addAll(group.participantIds());
            if (group.ghostId() != null) {
                involved.add(group.ghostId());
            }
        }
        if (new HashSet<>(real).size() != real.size()) {
            throw EventException.invalid("A participant can only be in one of the new groups.");
        }
        var found = participants.findAllById(involved);
        if (found.size() != involved.size()
                || !found.stream().allMatch(p -> p.getEventId().equals(eventId) && inCategory(event, category, p))) {
            throw EventException.invalid("Every participant must be from this event and category.");
        }
        if (!members.findByParticipantIdInAndGhostFalse(real).isEmpty()) {
            throw EventException.conflict("A participant is already in a group.");
        }
        var mat = schedule.soonestFree(event, clock.instant())
                .orElseThrow(() -> EventException.conflict("No mat has a referee yet."));
        var number = groups.maxNumber(eventId);
        var numbers = new ArrayList<Integer>();
        for (var group : request.groups()) {
            number++;
            save(event, category, mat, number, accountId, group);
            numbers.add(number);
        }
        return new CreateGroupsResponse(mat.getId(), mat.getNumber(), numbers);
    }

    private void save(Event event, EventCategory category, Mat mat, int number, UUID accountId, GroupRequest request) {
        var group = groups.save(
                new FightGroup(event.getId(), category.getId(), mat.getId(), number, accountId, clock.instant()));
        var order = new ArrayList<>(request.participantIds());
        for (int i = 0; i < order.size(); i++) {
            members.save(new GroupMember(group.getId(), order.get(i), i, false));
        }
        if (request.ghostId() != null) {
            members.save(new GroupMember(group.getId(), request.ghostId(), order.size(), true));
            order.add(request.ghostId());
        }
        var pairs = RoundRobin.pairs();
        for (int i = 0; i < pairs.size(); i++) {
            var pair = pairs.get(i);
            matches.save(new Match(
                    event.getId(), group.getId(), mat.getId(), i, order.get(pair.red()), order.get(pair.blue())));
        }
    }

    private static void checkShape(GroupRequest group) {
        var ids = group.participantIds();
        var expected = group.ghostId() == null ? RoundRobin.GROUP_SIZE : RoundRobin.GROUP_SIZE - 1;
        if (ids.size() != expected) {
            throw EventException.invalid("A group is 4 participants, or 3 and a ghost.");
        }
        if (new HashSet<>(ids).size() != ids.size() || ids.contains(group.ghostId())) {
            throw EventException.invalid("A participant appears twice in a group.");
        }
    }

    private EventCategory category(UUID eventId, UUID categoryId) {
        return categories
                .findById(categoryId)
                .filter(c -> c.getEventId().equals(eventId))
                .orElseThrow(EventException::notFound);
    }

    /** Participants competing for real in a group (not as ghosts), with that group. */
    private Map<UUID, FightGroup> groupedIds(UUID eventId) {
        var byId = groups.findByEventId(eventId).stream()
                .collect(Collectors.toMap(FightGroup::getId, Function.identity()));
        return members.findByEventId(eventId).stream()
                .filter(m -> !m.isGhost())
                .collect(Collectors.toMap(GroupMember::getParticipantId, m -> byId.get(m.getGroupId())));
    }

    private static boolean inCategory(Event event, EventCategory category, Participant participant) {
        return category.contains(event.ageOf(participant.getBirthDate()));
    }
}
