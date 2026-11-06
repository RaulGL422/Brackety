package dev.rgal.brackety.eventpackage;

import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.Cif;
import dev.rgal.brackety.auth.account.Profile;
import dev.rgal.brackety.auth.account.ProfileRepository;
import dev.rgal.brackety.demo.DemoAccounts;
import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventRepository;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.event.EventStaff;
import dev.rgal.brackety.event.EventStaffRepository;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.eventpackage.EventPackage.Category;
import dev.rgal.brackety.eventpackage.EventPackage.MatEntry;
import dev.rgal.brackety.eventpackage.EventPackage.Owner;
import dev.rgal.brackety.eventpackage.EventPackage.ParticipantEntry;
import dev.rgal.brackety.eventpackage.EventPackage.Settings;
import dev.rgal.brackety.eventpackage.EventPackage.StaffMember;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import jakarta.validation.Validator;
import java.time.Clock;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.json.JsonMapper;

/** Exports an event ready to run elsewhere and loads one into an empty database (docs/modulos/servidor-local.md). */
@Service
public class EventPackageService {

    private static final Logger log = LoggerFactory.getLogger(EventPackageService.class);

    private final EventService eventService;
    private final EventAccess access;
    private final EventRepository events;
    private final EventStaffRepository staff;
    private final EventCategoryRepository categories;
    private final MatRepository mats;
    private final ParticipantRepository participants;
    private final AccountRepository accounts;
    private final ProfileRepository profiles;
    private final DemoAccounts demoAccounts;
    private final JsonMapper json;
    private final Validator validator;
    private final Clock clock;

    EventPackageService(
            EventService eventService,
            EventAccess access,
            EventRepository events,
            EventStaffRepository staff,
            EventCategoryRepository categories,
            MatRepository mats,
            ParticipantRepository participants,
            AccountRepository accounts,
            ProfileRepository profiles,
            DemoAccounts demoAccounts,
            JsonMapper json,
            Validator validator,
            Clock clock) {
        this.eventService = eventService;
        this.access = access;
        this.events = events;
        this.staff = staff;
        this.categories = categories;
        this.mats = mats;
        this.participants = participants;
        this.accounts = accounts;
        this.profiles = profiles;
        this.demoAccounts = demoAccounts;
        this.json = json;
        this.validator = validator;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public EventPackage export(UUID eventId, UUID accountId) {
        access.require(eventId, accountId, EventRole.CLUB);
        var event = eventService.get(eventId);
        var eventStaff = staff.findByEventId(eventId);
        var usernames =
                accounts
                        .findAllById(eventStaff.stream()
                                .map(EventStaff::getAccountId)
                                .collect(Collectors.toSet()))
                        .stream()
                        .collect(Collectors.toMap(Account::getId, Account::getEmail));
        var eventCategories = categories.findByEventIdOrderByMinAge(eventId);
        var categoryNames =
                eventCategories.stream().collect(Collectors.toMap(EventCategory::getId, EventCategory::getName));
        var result = new EventPackage(
                EventPackage.SCHEMA_VERSION,
                clock.instant(),
                settings(event),
                owner(event.getOwnerAccountId()),
                eventStaff.stream()
                        .map(s -> new StaffMember(usernames.get(s.getAccountId()), s.getRole()))
                        .sorted(Comparator.comparing(StaffMember::role).thenComparing(StaffMember::username))
                        .toList(),
                eventCategories.stream()
                        .map(c ->
                                new Category(c.getName(), c.getMinAge(), c.getMaxAge(), c.getFormat(), c.getTeamSize()))
                        .toList(),
                mats.findByEventIdOrderByNumber(eventId).stream()
                        .map(m -> new MatEntry(m.getNumber(), usernames.get(m.getRefereeAccountId())))
                        .toList(),
                participants.findByEventIdOrderByFirstNameAscLastNameAsc(eventId).stream()
                        .map(p -> new ParticipantEntry(
                                p.getFirstName(),
                                p.getLastName(),
                                p.getBirthDate(),
                                p.getHeightCm(),
                                p.hasGuardianConsent(),
                                categoryNames.get(p.getCategoryId())))
                        .toList());
        log.info(
                "Event package exported: {} staff, {} categories, {} mats, {} participants",
                result.staff().size(),
                result.categories().size(),
                result.mats().size(),
                result.participants().size());
        return result;
    }

    /** All or nothing; refused if the database already has an event. Returns the new event's id. */
    @Transactional
    public UUID load(byte[] content) {
        var p = parse(content);
        if (events.count() > 0) {
            throw new InvalidEventPackageException(
                    "the database already has an event: a package only loads into an empty one");
        }
        EventPackageRules.check(p, validator);
        var accountIds = createAccounts(p);
        var settings = p.event();
        var event = events.save(new Event(
                accountIds.get(EventPackageRules.username(p.owner().username())),
                settings.name().strip(),
                settings.date(),
                settings.maxGroupsPerMat(),
                settings.matchSeconds(),
                settings.pointsLimit(),
                settings.changeoverSeconds(),
                settings.attendancePoints(),
                clock.instant()));
        for (var member : p.staff()) {
            staff.save(new EventStaff(event.getId(), accountIds.get(member.username()), member.role()));
        }
        for (var mat : p.mats()) {
            mats.save(new Mat(event.getId(), mat.number(), accountIds.get(mat.refereeUsername())));
        }
        var categoryIds = new HashMap<String, UUID>();
        for (var c : p.categories()) {
            var category = categories.save(
                    new EventCategory(event.getId(), c.name().strip(), c.minAge(), c.maxAge(), c.teamSize()));
            categoryIds.put(category.getName(), category.getId());
        }
        for (var entry : p.participants()) {
            var participant = new Participant(event.getId(), clock.instant());
            participant.update(
                    entry.firstName().strip(),
                    entry.lastName().strip(),
                    entry.birthDate(),
                    entry.heightCm(),
                    entry.guardianConsent(),
                    entry.categoryName() == null ? null : categoryIds.get(entry.categoryName()));
            participants.save(participant);
        }
        log.warn("Event package accounts that did not exist were created with their usernames as passwords");
        log.info(
                "Event package loaded: {} staff, {} categories, {} mats, {} participants",
                p.staff().size(),
                p.categories().size(),
                p.mats().size(),
                p.participants().size());
        return event.getId();
    }

    private EventPackage parse(byte[] content) {
        try {
            var tree = json.readTree(content);
            var version = tree.get("schemaVersion");
            if (version == null || !version.isInt()) {
                throw new InvalidEventPackageException("not an event package: schemaVersion is missing");
            }
            if (version.intValue() != EventPackage.SCHEMA_VERSION) {
                throw new InvalidEventPackageException("unknown schemaVersion " + version.intValue()
                        + " (this server reads " + EventPackage.SCHEMA_VERSION + ")");
            }
            return json.treeToValue(tree, EventPackage.class);
        } catch (JacksonException e) {
            throw new InvalidEventPackageException("not valid JSON for an event package at " + path(e));
        }
    }

    // Field names and indexes only: Jackson's own message may quote the content.
    private static String path(JacksonException e) {
        var path = e.getPath().stream()
                .map(r -> r.getPropertyName() != null ? "." + r.getPropertyName() : "[" + r.getIndex() + "]")
                .collect(Collectors.joining());
        var location = e.getLocation();
        return path.isEmpty() && location != null
                ? "line " + location.getLineNr() + ", column " + location.getColumnNr()
                : path.replaceFirst("^\\.", "");
    }

    /** Usernames → account ids; the owner gets a club profile, everyone else a helper one. */
    private Map<String, UUID> createAccounts(EventPackage p) {
        var owner = EventPackageRules.username(p.owner().username());
        var ids = new HashMap<String, UUID>();
        ids.put(
                owner,
                demoAccounts.club(
                        owner,
                        strip(p.owner().organizationName()),
                        Cif.normalize(p.owner().taxId())));
        for (var member : p.staff()) {
            ids.computeIfAbsent(member.username(), demoAccounts::helper);
        }
        return ids;
    }

    private static String strip(String value) {
        return value == null ? null : value.strip();
    }

    private static Settings settings(Event event) {
        return new Settings(
                event.getName(),
                event.getEventDate(),
                event.getMaxGroupsPerMat(),
                event.getMatchSeconds(),
                event.getPointsLimit(),
                event.getChangeoverSeconds(),
                event.getAttendancePoints());
    }

    private Owner owner(UUID accountId) {
        var username = accounts.findById(accountId).map(Account::getEmail).orElseThrow();
        var organization = profiles.findByAccountId(accountId).stream()
                .filter(Profile::isOrganizer)
                .findFirst();
        return new Owner(
                username,
                organization.map(Profile::getOrganizationName).orElse(null),
                organization.map(Profile::getTaxId).orElse(null));
    }
}
