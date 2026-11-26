package dev.rgal.brackety.event;

import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.event.dto.EventSettingsRequest;
import dev.rgal.brackety.event.dto.EventSettingsResponse;
import dev.rgal.brackety.event.dto.EventSettingsResponse.CategoryResponse;
import dev.rgal.brackety.event.dto.EventSettingsResponse.MatSettings;
import dev.rgal.brackety.event.dto.EventSettingsResponse.StaffMember;
import dev.rgal.brackety.event.dto.MeasureRules;
import dev.rgal.brackety.event.dto.MeasureRulesRequest;
import dev.rgal.brackety.event.dto.MyEventResponse;
import dev.rgal.brackety.event.dto.WarningReasons;
import dev.rgal.brackety.event.dto.WarningReasonsRequest;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
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
    private final EventOrganizationRepository organizations;
    private final AccountRepository accounts;
    private final StaffNames staffNames;
    private final EventAccess access;
    private final MatSync matSync;

    EventService(
            EventRepository events,
            EventStaffRepository staff,
            MatRepository mats,
            EventCategoryRepository categories,
            EventOrganizationRepository organizations,
            AccountRepository accounts,
            EventAccess access,
            StaffNames staffNames,
            MatSync matSync) {
        this.matSync = matSync;
        this.staffNames = staffNames;
        this.events = events;
        this.staff = staff;
        this.mats = mats;
        this.categories = categories;
        this.organizations = organizations;
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
        var leagueNames = new HashMap<UUID, String>();
        var saved = access.savedPermissionsOf(accountId);
        // Their first mat in each event, by number.
        var matByEvent = new HashMap<UUID, Mat>();
        mats.findByRefereeAccountIdOrderByNumber(accountId).forEach(m -> matByEvent.putIfAbsent(m.getEventId(), m));
        return events.findAllById(rolesByEvent.keySet()).stream()
                .sorted(Comparator.comparing(Event::getEventDate).reversed())
                .map(event -> {
                    var mat = Optional.ofNullable(matByEvent.get(event.getId()));
                    return new MyEventResponse(
                            event.getId(),
                            event.getName(),
                            event.getEventDate(),
                            rolesByEvent.get(event.getId()),
                            EventAccess.permissions(rolesByEvent.get(event.getId()), saved.get(event.getId())),
                            mat.map(Mat::getId).orElse(null),
                            mat.map(Mat::getNumber).orElse(null),
                            event.getLeagueId(),
                            leagueNames.computeIfAbsent(event.getLeagueId(), events::leagueName),
                            event.getPhaseNumber(),
                            event.weightRequirement(),
                            event.heightRequirement());
                })
                .toList();
    }

    @Transactional(readOnly = true)
    public EventSettingsResponse settings(UUID eventId, UUID accountId) {
        // Whoever adds participants needs the categories; the staff and their emails are the club's alone.
        access.require(eventId, accountId, EventPermission.PARTICIPANTS);
        if (!access.roles(eventId, accountId).contains(EventRole.CLUB)) {
            return settings(get(eventId)).withoutStaff();
        }
        return settings(get(eventId));
    }

    /** Whether the event asks for weight and height; null follows its sport. */
    @Transactional
    public MeasureRules updateMeasures(UUID eventId, UUID accountId, MeasureRulesRequest request) {
        access.require(eventId, accountId, EventRole.CLUB);
        var event = get(eventId);
        event.setMeasureRequirements(request.weight(), request.height());
        return MeasureRules.of(event);
    }

    /** The warning reasons the referee picks from; null follows the sport. */
    @Transactional
    public WarningReasons updateWarningReasons(UUID eventId, UUID accountId, WarningReasonsRequest request) {
        access.require(eventId, accountId, EventRole.CLUB);
        var event = get(eventId);
        event.setWarningReasons(request.reasons());
        return WarningReasons.of(event);
    }

    @Transactional
    public EventSettingsResponse updateSettings(UUID eventId, UUID accountId, EventSettingsRequest request) {
        access.require(eventId, accountId, EventRole.CLUB);
        // Locked like a match's first start: no match starts while the rules change.
        var event = lock(eventId);
        var referees = request.matReferees();
        requireEventReferees(eventId, referees);
        // The date sets every participant's age, and so the category their group was made for.
        if (!request.date().equals(event.getEventDate()) && events.hasGroupsOrTeams(eventId)) {
            throw EventException.conflict("DATE_LOCKED", "The date cannot change once there are groups or teams.");
        }
        var rules = NewRules.of(event.modality(), request);
        requireRulesCanChange(eventId, event.modality(), rules);
        var current = mats.findByEventIdOrderByNumber(eventId);
        requireMatsCanChange(current, referees);
        event.update(
                request.name().strip(),
                request.date(),
                Objects.requireNonNullElse(request.attendancePoints(), event.getAttendancePoints()),
                rules.individual(),
                rules.team(),
                rules.minRestSeconds(),
                rules.superiorityGap());
        updateMats(eventId, current, referees);
        return settings(event);
    }

    private void requireEventReferees(UUID eventId, List<UUID> matReferees) {
        var assigned = matReferees.stream().filter(Objects::nonNull).toList();
        if (!refereeIds(eventId).containsAll(assigned)) {
            throw EventException.invalid("Only the event's referees can be assigned to a mat.");
        }
        if (new HashSet<>(assigned).size() != assigned.size()) {
            throw EventException.invalid("A referee can only be on one mat.");
        }
    }

    private void requireRulesCanChange(UUID eventId, Modality modality, NewRules rules) {
        if (rules.changeLength(modality) && events.hasMatchIn(eventId, "IN_PROGRESS")) {
            throw EventException.conflict(
                    "LENGTH_LOCKED", "The match length cannot change while a match is in progress.");
        }
        // A disqualification scores the limit for the rival: started matches keep the one they had.
        if (rules.changeHowAMatchEnds(modality) && events.hasStartedMatches(eventId)) {
            throw EventException.conflict(
                    "POINTS_LIMIT_LOCKED", "The points limit cannot change once a match has started.");
        }
    }

    private void requireMatsCanChange(List<Mat> current, List<UUID> matReferees) {
        var removed = removed(current, matReferees);
        if (!removed.isEmpty()
                && events.hasGroupsOnMats(removed.stream().map(Mat::getId).toList())) {
            // Its groups say where they were played: a mat that is done goes out of use instead (Raul, 2026-11-18).
            throw EventException.conflict(
                    "MAT_HAS_GROUPS", "A mat with groups cannot be removed: disable it in the control panel.");
        }
        // Nobody would ever play the matches of a mat left without its referee (Raul, 2026-11-13).
        for (int i = 0; i < Math.min(current.size(), matReferees.size()); i++) {
            var mat = current.get(i);
            if (matReferees.get(i) == null
                    && mat.getRefereeAccountId() != null
                    && events.hasMatchesToPlayOn(mat.getId())) {
                throw EventException.conflict(
                        "MAT_HAS_MATCHES", "Mat " + mat.getNumber() + " has matches to play: it needs its referee.");
            }
        }
    }

    // Mat i + 1 gets referee i: new mats at the end, the last ones go when the list is shorter.
    private void updateMats(UUID eventId, List<Mat> current, List<UUID> matReferees) {
        if (!current.stream().map(Mat::getRefereeAccountId).toList().equals(matReferees)) {
            matSync.changed(eventId);
        }
        for (int i = 0; i < matReferees.size(); i++) {
            if (i < current.size()) {
                current.get(i).assignReferee(matReferees.get(i));
            } else {
                mats.save(new Mat(eventId, i + 1, matReferees.get(i)));
            }
        }
        mats.deleteAll(removed(current, matReferees));
    }

    private static List<Mat> removed(List<Mat> current, List<UUID> matReferees) {
        return current.size() > matReferees.size() ? current.subList(matReferees.size(), current.size()) : List.of();
    }

    /** Puts someone who may referee their mat on mat {@code number}, as the settings do (staff QR access). */
    @Transactional
    public void assignReferee(UUID eventId, int number, UUID refereeAccountId) {
        var mat = mats.findByEventIdOrderByNumber(eventId).stream()
                .filter(m -> m.getNumber() == number)
                .findFirst()
                .orElseThrow(EventException::notFound);
        mat.assignReferee(refereeAccountId);
        matSync.changed(eventId);
    }

    private EventSettingsResponse settings(Event event) {
        var names = staffNames.names(event.getId());
        var saved = access.savedPermissions(event.getId());
        var rolesByAccount = staff.findByEventId(event.getId()).stream()
                .collect(Collectors.groupingBy(
                        EventStaff::getAccountId, Collectors.mapping(EventStaff::getRole, Collectors.toList())));
        // Everyone but the club itself, by sign-in.
        var people = accounts.findAllById(rolesByAccount.keySet()).stream()
                .filter(a -> !rolesByAccount.get(a.getId()).contains(EventRole.CLUB))
                .sorted(Comparator.comparing(Account::getEmail))
                .map(a -> new StaffMember(
                        a.getId(),
                        a.getEmail(),
                        names.get(a.getId()),
                        rolesByAccount.get(a.getId()).stream().sorted().toList(),
                        EventAccess.permissions(EnumSet.copyOf(rolesByAccount.get(a.getId())), saved.get(a.getId()))))
                .toList();
        var referees = people.stream()
                .filter(p -> p.permissions().contains(EventPermission.OWN_MAT))
                .toList();
        return new EventSettingsResponse(
                event.getName(),
                event.getEventDate(),
                event.modality().individual().matchSeconds(),
                event.modality().individual().pointsLimit(),
                mats.findByEventIdOrderByNumber(event.getId()).stream()
                        .map(m -> new MatSettings(m.getId(), m.getNumber(), m.getRefereeAccountId()))
                        .toList(),
                referees,
                people,
                categories.findByEventIdOrderByMinAge(event.getId()).stream()
                        .map(CategoryResponse::of)
                        .toList(),
                EventOrganizationService.list(organizations, event.getId()),
                event.getAttendancePoints(),
                event.getPhaseNumber(),
                event.getSport().code(),
                event.modality().team().matchSeconds(),
                event.modality().team().pointsLimit(),
                event.modality().getMinRestSeconds(),
                MeasureRules.of(event),
                WarningReasons.of(event),
                event.modality().scoring());
    }

    private List<UUID> refereeIds(UUID eventId) {
        // Whoever may referee their mat, not only those invited as referees; never the club itself.
        return staff.findByEventId(eventId).stream()
                .map(EventStaff::getAccountId)
                .distinct()
                .filter(id -> !access.roles(eventId, id).contains(EventRole.CLUB))
                .filter(id -> access.has(eventId, id, EventPermission.OWN_MAT))
                .toList();
    }
}
