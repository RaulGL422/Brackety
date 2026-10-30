package dev.rgal.brackety.event;

import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.event.dto.EventSettingsRequest;
import dev.rgal.brackety.event.dto.EventSettingsResponse;
import dev.rgal.brackety.event.dto.EventSettingsResponse.CategoryResponse;
import dev.rgal.brackety.event.dto.EventSettingsResponse.MatSettings;
import dev.rgal.brackety.event.dto.EventSettingsResponse.StaffMember;
import dev.rgal.brackety.event.dto.MyEventResponse;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class EventService {

    private final EventRepository events;
    private final EventStaffRepository staff;
    private final MatRepository mats;
    private final EventCategoryRepository categories;
    private final AccountRepository accounts;
    private final EventAccess access;

    EventService(
            EventRepository events,
            EventStaffRepository staff,
            MatRepository mats,
            EventCategoryRepository categories,
            AccountRepository accounts,
            EventAccess access) {
        this.events = events;
        this.staff = staff;
        this.mats = mats;
        this.categories = categories;
        this.accounts = accounts;
        this.access = access;
    }

    public Event get(UUID eventId) {
        return events.findById(eventId).orElseThrow(EventException::notFound);
    }

    /** Locks the event row until the transaction ends; see {@link EventRepository#lockById}. */
    public Event lock(UUID eventId) {
        return events.lockById(eventId).orElseThrow(EventException::notFound);
    }

    @Transactional(readOnly = true)
    public List<MyEventResponse> myEvents(UUID accountId) {
        var rolesByEvent = staff.findByAccountId(accountId).stream()
                .collect(Collectors.groupingBy(
                        EventStaff::getEventId,
                        Collectors.mapping(
                                EventStaff::getRole, Collectors.toCollection(() -> EnumSet.noneOf(EventRole.class)))));
        return events.findAllById(rolesByEvent.keySet()).stream()
                .sorted(Comparator.comparing(Event::getEventDate).reversed())
                .map(event -> {
                    var mat = mats.findByEventIdOrderByNumber(event.getId()).stream()
                            .filter(m -> accountId.equals(m.getRefereeAccountId()))
                            .findFirst();
                    return new MyEventResponse(
                            event.getId(),
                            event.getName(),
                            event.getEventDate(),
                            rolesByEvent.get(event.getId()),
                            mat.map(Mat::getId).orElse(null),
                            mat.map(Mat::getNumber).orElse(null));
                })
                .toList();
    }

    @Transactional(readOnly = true)
    public EventSettingsResponse settings(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        return settings(get(eventId));
    }

    @Transactional
    public EventSettingsResponse updateSettings(UUID eventId, UUID accountId, EventSettingsRequest request) {
        access.require(eventId, accountId, EventRole.CLUB);
        var event = get(eventId);
        var referees = refereeIds(eventId);
        var assigned = request.matReferees().stream().filter(Objects::nonNull).toList();
        if (!referees.containsAll(assigned)) {
            throw EventException.invalid("Only the event's referees can be assigned to a mat.");
        }
        if (new HashSet<>(assigned).size() != assigned.size()) {
            throw EventException.invalid("A referee can only be on one mat.");
        }
        // The date sets every participant's age, and so the category their group was made for.
        if (!request.date().equals(event.getEventDate()) && events.hasGroups(eventId)) {
            throw EventException.conflict("The date cannot change once there are groups.");
        }
        var current = mats.findByEventIdOrderByNumber(eventId);
        var removed = current.size() > request.matReferees().size()
                ? current.subList(request.matReferees().size(), current.size())
                : List.<Mat>of();
        if (!removed.isEmpty()
                && events.hasGroupsOnMats(removed.stream().map(Mat::getId).toList())) {
            throw EventException.conflict("A mat with groups cannot be removed.");
        }
        event.update(request.name().strip(), request.date(), request.maxGroupsPerMat());
        for (int i = 0; i < request.matReferees().size(); i++) {
            var referee = request.matReferees().get(i);
            if (i < current.size()) {
                current.get(i).assignReferee(referee);
            } else {
                mats.save(new Mat(eventId, i + 1, referee));
            }
        }
        mats.deleteAll(removed);
        return settings(event);
    }

    private EventSettingsResponse settings(Event event) {
        var referees = accounts.findAllById(refereeIds(event.getId())).stream()
                .sorted(Comparator.comparing(Account::getEmail))
                .map(a -> new StaffMember(a.getId(), a.getEmail()))
                .toList();
        return new EventSettingsResponse(
                event.getName(),
                event.getEventDate(),
                event.getMaxGroupsPerMat(),
                event.getMatchSeconds(),
                event.getPointsLimit(),
                mats.findByEventIdOrderByNumber(event.getId()).stream()
                        .map(m -> new MatSettings(m.getId(), m.getNumber(), m.getRefereeAccountId()))
                        .toList(),
                referees,
                categories.findByEventIdOrderByMinAge(event.getId()).stream()
                        .map(c -> new CategoryResponse(c.getId(), c.getName(), c.getMinAge(), c.getMaxAge()))
                        .toList());
    }

    private List<UUID> refereeIds(UUID eventId) {
        return staff.findByEventIdAndRole(eventId, EventRole.REFEREE).stream()
                .map(EventStaff::getAccountId)
                .toList();
    }
}
