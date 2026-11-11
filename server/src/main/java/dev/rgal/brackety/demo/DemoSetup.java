package dev.rgal.brackety.demo;

import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventOrganization;
import dev.rgal.brackety.event.EventOrganizationRepository;
import dev.rgal.brackety.event.EventRepository;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventStaff;
import dev.rgal.brackety.event.EventStaffRepository;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.league.League;
import dev.rgal.brackety.league.LeagueRepository;
import java.time.Clock;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionOperations;

/**
 * Accounts and event for the Liga Yoseikan phase 1 prototype (docs/modulos/prototipo-f1.md).
 * Usernames double as passwords: a risk accepted for this phase only, so it runs only with
 * DEMO_ACCOUNTS_ENABLED=true and does nothing once the accounts or any event exist. With an event package to load
 * (BRACKETY_PACKAGE) it does nothing either: the package brings its own event and accounts.
 */
@Component
public class DemoSetup {

    private static final String CLUB = "club1";
    // Fictional organization, with a CIF that only passes the check digit.
    private static final String DEMO_CLUB_NAME = "Club Demo Yoseikan";
    private static final String DEMO_CLUB_CIF = "G12345674";
    // Fictional organizations taking part, so the club column has something to show.
    public static final List<String> ORGANIZATIONS = List.of(DEMO_CLUB_NAME, "Escuela Yoseikan Sur");
    private static final List<String> GROUPERS = List.of("ayudante1", "ayudante2");
    private static final List<String> REFEREES = List.of("arbitro1", "arbitro2", "arbitro3", "arbitro4", "arbitro5");

    // Placeholder categories (ranking age bands, mixed) until the real ones are confirmed; the four
    // oldest are by teams of 3 as an example of team categories (docs/modulos/prototipo-f1-equipos.md).
    private static final List<AgeBand> CATEGORIES = List.of(
            new AgeBand("4-6", 4, 6, null),
            new AgeBand("7-8", 7, 8, null),
            new AgeBand("9-10", 9, 10, null),
            new AgeBand("11-12", 11, 12, null),
            new AgeBand("13-14", 13, 14, null),
            new AgeBand("15-16", 15, 16, 3),
            new AgeBand("17-19", 17, 19, 3),
            new AgeBand("20-25", 20, 25, 3),
            new AgeBand("26+", 26, 120, 3));

    private static final Logger log = LoggerFactory.getLogger(DemoSetup.class);

    private final AccountRepository accounts;
    private final DemoAccounts demoAccounts;
    private final EventRepository events;
    private final EventStaffRepository staff;
    private final MatRepository mats;
    private final EventCategoryRepository categories;
    private final EventOrganizationRepository organizations;
    private final LeagueRepository leagues;
    private final TransactionOperations transactions;
    private final Clock clock;
    private final boolean enabled;
    private final String eventDate;
    private final String eventPackage;

    DemoSetup(
            AccountRepository accounts,
            DemoAccounts demoAccounts,
            EventRepository events,
            EventStaffRepository staff,
            MatRepository mats,
            EventCategoryRepository categories,
            EventOrganizationRepository organizations,
            LeagueRepository leagues,
            TransactionOperations transactions,
            Clock clock,
            @Value("${brackety.demo.enabled}") boolean enabled,
            @Value("${brackety.demo.event-date}") String eventDate,
            @Value("${brackety.package}") String eventPackage) {
        this.accounts = accounts;
        this.demoAccounts = demoAccounts;
        this.events = events;
        this.staff = staff;
        this.mats = mats;
        this.categories = categories;
        this.organizations = organizations;
        this.leagues = leagues;
        this.transactions = transactions;
        this.clock = clock;
        this.enabled = enabled;
        this.eventDate = eventDate;
        this.eventPackage = eventPackage;
    }

    @EventListener(ApplicationReadyEvent.class)
    void onStartup() {
        if (enabled && !eventPackage.isBlank()) {
            log.warn("Demo accounts are enabled but an event package is set: no demo event is created");
        } else if (enabled) {
            log.warn("Demo accounts are enabled: their passwords equal their usernames");
            seed();
        }
    }

    /** Creates the demo accounts and event unless they or any event exist; returns the event id or null. */
    public UUID seed() {
        return transactions.execute(status -> {
            if (accounts.findByEmail(CLUB).isPresent() || events.count() > 0) {
                return null;
            }
            var now = clock.instant();
            var club = demoAccounts.club(CLUB, DEMO_CLUB_NAME, DEMO_CLUB_CIF);
            var date = eventDate.isBlank() ? LocalDate.now(clock) : LocalDate.parse(eventDate);
            var league = leagues.save(new League(club, "Liga Yoseikan 2027", now));
            var event =
                    events.save(Event.tambo(club, league.getId(), "Liga Yoseikan 2027 · Fase 1 · Tambo", date, now));
            staff.save(new EventStaff(event.getId(), club, EventRole.CLUB));
            for (var grouper : GROUPERS) {
                staff.save(new EventStaff(event.getId(), demoAccounts.helper(grouper), EventRole.GROUPER));
            }
            for (int i = 0; i < REFEREES.size(); i++) {
                var referee = demoAccounts.helper(REFEREES.get(i));
                staff.save(new EventStaff(event.getId(), referee, EventRole.REFEREE));
                mats.save(new Mat(event.getId(), i + 1, referee));
            }
            for (var c : CATEGORIES) {
                categories.save(new EventCategory(event.getId(), c.name(), c.minAge(), c.maxAge(), c.teamSize()));
            }
            for (var name : ORGANIZATIONS) {
                organizations.save(new EventOrganization(event.getId(), name, null));
            }
            return event.getId();
        });
    }

    /** {@code teamSize}: null for an individual category. */
    private record AgeBand(String name, int minAge, int maxAge, Integer teamSize) {}
}
