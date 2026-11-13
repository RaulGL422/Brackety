package dev.rgal.brackety.eventpackage;

import dev.rgal.brackety.auth.account.Account;
import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.Cif;
import dev.rgal.brackety.auth.account.Profile;
import dev.rgal.brackety.auth.account.ProfileRepository;
import dev.rgal.brackety.common.crypto.Sha256;
import dev.rgal.brackety.demo.DemoAccounts;
import dev.rgal.brackety.event.Discipline;
import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventOrganization;
import dev.rgal.brackety.event.EventOrganizationRepository;
import dev.rgal.brackety.event.EventRepository;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.event.EventStaff;
import dev.rgal.brackety.event.EventStaffRepository;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.event.StaffNames;
import dev.rgal.brackety.eventpackage.EventPackage.Category;
import dev.rgal.brackety.eventpackage.EventPackage.CategoryPodiumEntry;
import dev.rgal.brackety.eventpackage.EventPackage.LeagueEntry;
import dev.rgal.brackety.eventpackage.EventPackage.MatEntry;
import dev.rgal.brackety.eventpackage.EventPackage.OrganizationEntry;
import dev.rgal.brackety.eventpackage.EventPackage.Owner;
import dev.rgal.brackety.eventpackage.EventPackage.ParticipantEntry;
import dev.rgal.brackety.eventpackage.EventPackage.Settings;
import dev.rgal.brackety.eventpackage.EventPackage.StaffMember;
import dev.rgal.brackety.eventpackage.LoadedPackage.NewAccount;
import dev.rgal.brackety.league.CategoryPodium;
import dev.rgal.brackety.league.CategoryPodiumRepository;
import dev.rgal.brackety.league.League;
import dev.rgal.brackety.league.LeagueRepository;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import jakarta.validation.Validator;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.text.Normalizer;
import java.time.Clock;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.zip.ZipInputStream;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.interceptor.TransactionAspectSupport;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.json.JsonMapper;

/**
 * Exports an event ready to run elsewhere, loads one into an empty database and imports the results of one back
 * (docs/modulos/servidor-local.md).
 */
@Service
public class EventPackageService {

    /** The package's name inside the full export (.zip). */
    public static final String ZIP_ENTRY = "evento.brackety";

    private static final int MAX_PACKAGE_BYTES = 50 * 1024 * 1024;

    private static final Logger log = LoggerFactory.getLogger(EventPackageService.class);

    private final EventService eventService;
    private final EventAccess access;
    private final EventRepository events;
    private final EventStaffRepository staff;
    private final EventCategoryRepository categories;
    private final EventOrganizationRepository organizations;
    private final MatRepository mats;
    private final ParticipantRepository participants;
    private final LeagueRepository leagues;
    private final CategoryPodiumRepository podiums;
    private final AccountRepository accounts;
    private final ProfileRepository profiles;
    private final DemoAccounts demoAccounts;
    private final EventResultsTransfer results;
    private final JsonMapper json;
    private final Validator validator;
    private final Clock clock;
    private final StaffNames staffNames;

    EventPackageService(
            EventService eventService,
            EventAccess access,
            EventRepository events,
            EventStaffRepository staff,
            EventCategoryRepository categories,
            EventOrganizationRepository organizations,
            MatRepository mats,
            ParticipantRepository participants,
            LeagueRepository leagues,
            CategoryPodiumRepository podiums,
            AccountRepository accounts,
            ProfileRepository profiles,
            DemoAccounts demoAccounts,
            EventResultsTransfer results,
            JsonMapper json,
            Validator validator,
            Clock clock,
            StaffNames staffNames) {
        this.eventService = eventService;
        this.access = access;
        this.events = events;
        this.staff = staff;
        this.categories = categories;
        this.organizations = organizations;
        this.mats = mats;
        this.participants = participants;
        this.leagues = leagues;
        this.podiums = podiums;
        this.accounts = accounts;
        this.profiles = profiles;
        this.demoAccounts = demoAccounts;
        this.results = results;
        this.json = json;
        this.validator = validator;
        this.clock = clock;
        this.staffNames = staffNames;
    }

    /** "liga-yoseikan-fase-1-2027-03-10": a file name for the event's exports. */
    public static String fileName(Event event) {
        return slug(event.getName()) + "-" + event.getEventDate();
    }

    /** "Liga Yoseikan · Fase 1" → "liga-yoseikan-fase-1". */
    static String slug(String name) {
        var slug = Normalizer.normalize(name, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9]+", "-")
                .replaceAll("^-|-$", "");
        return slug.isEmpty() ? "evento" : slug;
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
        var eventOrganizations = organizations.findByEventIdOrderByName(eventId);
        var organizationNames = eventOrganizations.stream()
                .collect(Collectors.toMap(EventOrganization::getId, EventOrganization::getName));
        var result = new EventPackage(
                EventPackage.SCHEMA_VERSION,
                clock.instant(),
                settings(event),
                league(event),
                owner(event.getOwnerAccountId()),
                eventStaff.stream()
                        .map(s -> new StaffMember(usernames.get(s.getAccountId()), s.getRole()))
                        .sorted(Comparator.comparing(StaffMember::role).thenComparing(StaffMember::username))
                        .toList(),
                eventCategories.stream()
                        .map(c ->
                                new Category(c.getName(), c.getMinAge(), c.getMaxAge(), c.getFormat(), c.getTeamSize()))
                        .toList(),
                eventOrganizations.stream()
                        .map(o -> new OrganizationEntry(o.getName(), o.getShortName()))
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
                                categoryNames.get(p.getCategoryId()),
                                p.getPersonId(),
                                organizationNames.get(p.getOrganizationId())))
                        .toList(),
                results.export(eventId),
                staffNames.names(eventId).entrySet().stream()
                        .filter(e -> usernames.containsKey(e.getKey()))
                        .map(e -> new EventPackage.StaffName(usernames.get(e.getKey()), e.getValue()))
                        .sorted(Comparator.comparing(EventPackage.StaffName::username))
                        .toList());
        log.info(
                "Event package exported: {} staff, {} categories, {} mats, {} participants, {}",
                result.staff().size(),
                result.categories().size(),
                result.mats().size(),
                result.participants().size(),
                EventResultsTransfer.summary(result.results()));
        return result;
    }

    /** All or nothing; refused if the database already has an event. Results in the package load too. */
    @Transactional
    public LoadedPackage load(byte[] content) {
        var p = parse(content);
        if (events.count() > 0) {
            throw new InvalidEventPackageException(
                    "the database already has an event: a package only loads into an empty one");
        }
        EventPackageRules.check(p, validator);
        var passwords = new HashMap<String, String>();
        var accountIds = createAccounts(p, passwords);
        var settings = p.event();
        var ownerId = accountIds.get(EventPackageRules.username(p.owner().username()));
        var leagueEntry = p.league();
        var league = new League(
                ownerId,
                leagueEntry != null
                        ? leagueEntry.name().strip()
                        : settings.name().strip(),
                clock.instant());
        if (leagueEntry != null) {
            league.update(league.getName(), leagueEntry.podium());
        }
        league = leagues.save(league);
        if (leagueEntry != null) {
            for (var c : leagueEntry.categoryPodiums()) {
                podiums.save(new CategoryPodium(league.getId(), c.categoryName().strip(), c.podium()));
            }
        }
        var event = new Event(
                ownerId,
                league.getId(),
                leagueEntry != null ? leagueEntry.phaseNumber() : 1,
                leagueEntry != null ? leagueEntry.discipline() : Discipline.TAMBO,
                settings.name().strip(),
                settings.date(),
                settings.maxGroupsPerMat(),
                settings.matchSeconds(),
                settings.pointsLimit(),
                settings.changeoverSeconds(),
                settings.attendancePoints(),
                clock.instant());
        event.withTeamRules(
                Objects.requireNonNullElse(settings.teamMatchSeconds(), event.getTeamMatchSeconds()),
                Objects.requireNonNullElse(settings.teamPointsLimit(), event.getTeamPointsLimit()),
                Objects.requireNonNullElse(settings.minRestSeconds(), event.getMinRestSeconds()));
        event.setOriginEventId(settings.originId());
        event = events.save(event);
        for (var member : p.staff()) {
            staff.save(new EventStaff(event.getId(), accountIds.get(member.username()), member.role()));
        }
        // The names go in by SQL: the event and its staff must be written first.
        staff.flush();
        for (var name : p.staffNamesOrEmpty()) {
            if (accountIds.containsKey(name.username())) {
                staffNames.put(event.getId(), accountIds.get(name.username()), name.name());
            }
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
        var organizationIds = new HashMap<String, UUID>();
        for (var o : p.organizationsOrEmpty()) {
            var organization = organizations.save(
                    new EventOrganization(event.getId(), o.name().strip(), blankToNull(o.shortName())));
            organizationIds.put(organization.getName(), organization.getId());
        }
        for (var entry : p.participants()) {
            participants.save(newParticipant(event.getId(), entry, categoryIds, organizationIds));
        }
        if (p.results() != null && !p.results().isEmpty()) {
            participants.flush();
            mats.flush();
            results.write(event.getId(), p.results(), Map.of());
            event.setResultsImportHash(hash(p.results()));
        }
        log.info(
                "Event package loaded: {} staff, {} categories, {} mats, {} participants, {} new accounts",
                p.staff().size(),
                p.categories().size(),
                p.mats().size(),
                p.participants().size(),
                passwords.size());
        return new LoadedPackage(event.getId(), newAccounts(p, passwords));
    }

    /**
     * Brings the results of this event, run on another server (the hall laptop), into it. Participants are matched by
     * person id, or by name and birth date; those not here are added, as are missing mats, categories and
     * organizations. Refused when the event already has groups or teams of its own; importing the same results again
     * changes nothing. With {@code dryRun} nothing is kept: it says what would happen.
     */
    @Transactional
    public ResultsImport importResults(UUID eventId, UUID accountId, byte[] content, boolean dryRun) {
        access.require(eventId, accountId, EventRole.CLUB);
        var event = eventService.lock(eventId);
        EventPackage p;
        try {
            p = parse(content);
            EventPackageRules.check(p, validator);
        } catch (InvalidEventPackageException e) {
            throw EventException.invalid("Not a valid event file: " + e.getMessage());
        }
        if (!isSameEvent(event, p.event())) {
            throw EventException.conflict(
                    "RESULTS_OTHER_EVENT", "The file is from another event (different id, name or date).");
        }
        if (p.results() == null || p.results().isEmpty()) {
            throw EventException.invalid("The file has no results: no groups, teams or matches.");
        }
        var hash = hash(p.results());
        if (hash.equals(event.getResultsImportHash())) {
            return ResultsImport.of(p.results(), true, new Added(0, 0, 0, 0));
        }
        if (events.hasGroupsOrTeams(eventId)) {
            throw EventException.conflict(
                    "RESULTS_CONFLICT",
                    "The event already has groups or teams of its own: results are only imported into an event"
                            + " without competition.");
        }
        var aliases = new HashMap<UUID, UUID>();
        var added = addMissing(eventId, p, aliases);
        try {
            results.write(eventId, p.results(), aliases);
        } catch (InvalidEventPackageException e) {
            throw EventException.invalid("Not a valid event file: " + e.getMessage());
        }
        event.setResultsImportHash(hash);
        if (dryRun) {
            TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
        } else {
            log.info("Results imported: {}", EventResultsTransfer.summary(p.results()));
        }
        return ResultsImport.of(p.results(), false, added);
    }

    /**
     * What an import brings. {@code alreadyImported}: the same results were imported before, nothing changes.
     * {@code teams} counts real teams only (a ghost team exists only for its group).
     */
    public record ResultsImport(
            boolean alreadyImported,
            int newParticipants,
            int newMats,
            int newCategories,
            int newOrganizations,
            int teams,
            int groups,
            int matches,
            int actions) {

        static ResultsImport of(EventResults r, boolean alreadyImported, Added added) {
            return new ResultsImport(
                    alreadyImported,
                    added.participants(),
                    added.mats(),
                    added.categories(),
                    added.organizations(),
                    (int) r.teams().stream().filter(t -> !t.ghost()).count(),
                    r.groups().size(),
                    r.matches().size(),
                    r.actionCount());
        }
    }

    private record Added(int participants, int mats, int categories, int organizations) {}

    // The laptop's event knows the id it has here; a package from before ids travelled must match name and date.
    private static boolean isSameEvent(Event event, Settings settings) {
        if (settings.originId() != null) {
            return settings.originId().equals(event.getId());
        }
        return settings.date().equals(event.getEventDate())
                && settings.name().strip().equals(event.getName());
    }

    /**
     * Adds what the results need and the event lacks. A participant entered again on the laptop (other person id,
     * same name and birth date) goes in {@code aliases}: package person id → the one here.
     */
    private Added addMissing(UUID eventId, EventPackage p, Map<UUID, UUID> aliases) {
        var categoryIds = categories.findByEventIdOrderByMinAge(eventId).stream()
                .collect(Collectors.toMap(EventCategory::getName, EventCategory::getId));
        var newCategories = 0;
        for (var c : p.categories()) {
            if (!categoryIds.containsKey(c.name().strip())) {
                var category = categories.save(
                        new EventCategory(eventId, c.name().strip(), c.minAge(), c.maxAge(), c.teamSize()));
                categoryIds.put(category.getName(), category.getId());
                newCategories++;
            }
        }
        var matNumbers = mats.findByEventIdOrderByNumber(eventId).stream()
                .map(Mat::getNumber)
                .collect(Collectors.toSet());
        var newMats = 0;
        for (var m : p.mats()) {
            if (matNumbers.add(m.number())) {
                mats.save(new Mat(eventId, m.number(), null));
                newMats++;
            }
        }
        var organizationIds = organizations.findByEventIdOrderByName(eventId).stream()
                .collect(Collectors.toMap(EventOrganization::getName, EventOrganization::getId));
        var newOrganizations = 0;
        for (var o : p.organizationsOrEmpty()) {
            if (!organizationIds.containsKey(o.name().strip())) {
                var organization = organizations.save(
                        new EventOrganization(eventId, o.name().strip(), blankToNull(o.shortName())));
                organizationIds.put(organization.getName(), organization.getId());
                newOrganizations++;
            }
        }
        var here = participants.findByEventIdOrderByFirstNameAscLastNameAsc(eventId);
        var persons = here.stream().map(Participant::getPersonId).collect(Collectors.toSet());
        var newParticipants = 0;
        for (var entry : p.participants()) {
            if (entry.personId() != null && persons.contains(entry.personId())) {
                continue;
            }
            var same = here.stream()
                    .filter(x -> x.getFirstName()
                                    .equalsIgnoreCase(entry.firstName().strip())
                            && x.getLastName().equalsIgnoreCase(entry.lastName().strip())
                            && x.getBirthDate().equals(entry.birthDate()))
                    .findFirst();
            if (same.isPresent()) {
                if (entry.personId() != null) {
                    aliases.put(entry.personId(), same.get().getPersonId());
                }
                continue;
            }
            participants.save(newParticipant(eventId, entry, categoryIds, organizationIds));
            newParticipants++;
        }
        participants.flush();
        mats.flush();
        categories.flush();
        return new Added(newParticipants, newMats, newCategories, newOrganizations);
    }

    private Participant newParticipant(
            UUID eventId, ParticipantEntry entry, Map<String, UUID> categoryIds, Map<String, UUID> organizationIds) {
        var participant = new Participant(
                eventId, entry.personId() != null ? entry.personId() : UUID.randomUUID(), clock.instant());
        participant.update(
                entry.firstName().strip(),
                entry.lastName().strip(),
                entry.birthDate(),
                entry.heightCm(),
                entry.guardianConsent(),
                entry.categoryName() == null ? null : categoryIds.get(entry.categoryName()));
        participant.setOrganizationId(
                entry.organizationName() == null
                        ? null
                        : organizationIds.get(entry.organizationName().strip()));
        return participant;
    }

    private String hash(EventResults r) {
        return Sha256.hex(json.writeValueAsString(r));
    }

    private static List<NewAccount> newAccounts(EventPackage p, Map<String, String> passwords) {
        return passwords.entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .map(e -> new NewAccount(
                        e.getKey(),
                        p.staff().stream()
                                .filter(s -> s.username().equals(e.getKey()))
                                .map(s -> s.role().name())
                                .collect(Collectors.joining(",")),
                        e.getValue(),
                        p.mats().stream()
                                .filter(m -> e.getKey().equals(m.refereeUsername()))
                                .map(m -> String.valueOf(m.number()))
                                .collect(Collectors.joining(","))))
                .toList();
    }

    /** The package JSON, or the full export (.zip) that holds it as {@value #ZIP_ENTRY}. */
    private EventPackage parse(byte[] content) {
        var packageJson = isZip(content) ? fromZip(content) : content;
        try {
            var tree = json.readTree(packageJson);
            var version = tree.get("schemaVersion");
            if (version == null || !version.isInt()) {
                throw new InvalidEventPackageException("not an event package: schemaVersion is missing");
            }
            if (version.intValue() < 1 || version.intValue() > EventPackage.SCHEMA_VERSION) {
                throw new InvalidEventPackageException("unknown schemaVersion " + version.intValue()
                        + " (this server reads 1 to " + EventPackage.SCHEMA_VERSION + ")");
            }
            return json.treeToValue(tree, EventPackage.class);
        } catch (JacksonException e) {
            throw new InvalidEventPackageException("not valid JSON for an event package at " + path(e));
        }
    }

    static boolean isZip(byte[] content) {
        return content.length > 4 && content[0] == 'P' && content[1] == 'K' && content[2] == 3 && content[3] == 4;
    }

    private static byte[] fromZip(byte[] content) {
        try (var zip = new ZipInputStream(new ByteArrayInputStream(content))) {
            for (var entry = zip.getNextEntry(); entry != null; entry = zip.getNextEntry()) {
                if (entry.getName().endsWith(".brackety")) {
                    return zip.readNBytes(MAX_PACKAGE_BYTES);
                }
            }
        } catch (IOException e) {
            throw new InvalidEventPackageException("not a valid .zip file");
        }
        throw new InvalidEventPackageException("the .zip file has no " + ZIP_ENTRY);
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

    /**
     * Usernames → account ids; the owner gets a club profile, everyone else a helper one. Accounts that already exist
     * keep their password; the new ones get a random one, added to {@code passwords}.
     */
    private Map<String, UUID> createAccounts(EventPackage p, Map<String, String> passwords) {
        var owner = EventPackageRules.username(p.owner().username());
        var ids = new HashMap<String, UUID>();
        ids.put(
                owner,
                existing(owner)
                        .orElseGet(() -> demoAccounts.club(
                                owner,
                                blankToNull(p.owner().organizationName()),
                                Cif.normalize(p.owner().taxId()),
                                newPassword(owner, passwords))));
        for (var member : p.staff()) {
            var username = member.username();
            ids.computeIfAbsent(
                    username, u -> existing(u).orElseGet(() -> demoAccounts.helper(u, newPassword(u, passwords))));
        }
        return ids;
    }

    private Optional<UUID> existing(String username) {
        return accounts.findByEmail(username).map(Account::getId);
    }

    private static String newPassword(String username, Map<String, String> passwords) {
        var password = StaffPasswords.next();
        passwords.put(username, password);
        return password;
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.strip();
    }

    private static Settings settings(Event event) {
        return new Settings(
                event.getName(),
                event.getEventDate(),
                event.getMaxGroupsPerMat(),
                event.getMatchSeconds(),
                event.getPointsLimit(),
                event.getChangeoverSeconds(),
                event.getAttendancePoints(),
                Objects.requireNonNullElse(event.getOriginEventId(), event.getId()),
                event.getTeamMatchSeconds(),
                event.getTeamPointsLimit(),
                event.getMinRestSeconds());
    }

    private LeagueEntry league(Event event) {
        var league = leagues.findById(event.getLeagueId()).orElseThrow();
        return new LeagueEntry(
                league.getName(),
                event.getPhaseNumber(),
                event.getDiscipline(),
                league.getPodium(),
                podiums.findByLeagueIdOrderByCategoryName(league.getId()).stream()
                        .map(c -> new CategoryPodiumEntry(c.getCategoryName(), c.getPodium()))
                        .toList());
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
