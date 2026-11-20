package dev.rgal.brackety.devdata.scenarios;

import dev.rgal.brackety.auth.account.VerifiedAccounts;
import dev.rgal.brackety.devdata.DevScenario;
import dev.rgal.brackety.devdata.Scenario;
import dev.rgal.brackety.devdata.ScenarioContext;
import dev.rgal.brackety.event.Discipline;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventOrganization;
import dev.rgal.brackety.event.EventOrganizationRepository;
import dev.rgal.brackety.event.EventRole;
import dev.rgal.brackety.event.EventStaff;
import dev.rgal.brackety.event.EventStaffRepository;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.event.OrganizationRepository;
import dev.rgal.brackety.league.NewEventService;
import dev.rgal.brackety.league.dto.LeagueDtos.NewEventRequest;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import dev.rgal.brackety.participant.Sex;
import java.math.BigDecimal;
import java.util.List;
import java.util.Random;
import java.util.UUID;

/**
 * A grappling event as the FELODA one (docs/producto/grappling.md, G5): created as a standalone event, with the
 * FELODA age bands, gi and no-gi, the weight in the category name and everyone placed by hand, since the gi and
 * no-gi categories of an age overlap.
 */
@DevScenario
class GrapplingScenario implements Scenario {

    static final List<Band> CATEGORIES = List.of(
            new Band("U13 Gi", 12, 13, 240, null, 4, 35),
            new Band("U13 Sin gi", 12, 13, 240, null, 3, 38),
            new Band("U15 M -50 kg Sin gi", 14, 15, 240, Sex.MALE, 5, 46),
            new Band("U15 F Gi", 14, 15, 240, Sex.FEMALE, 3, 44),
            new Band("U17 M -65 kg Gi", 16, 17, 300, Sex.MALE, 4, 61),
            // Only two: a single match decides it.
            new Band("U20 M Sin gi", 18, 20, 300, Sex.MALE, 2, 74),
            new Band("Sénior M -77 kg Gi", 21, 34, 300, Sex.MALE, 6, 73),
            new Band("Sénior M -77 kg Sin gi", 21, 34, 300, Sex.MALE, 4, 73),
            new Band("Sénior F -64 kg Sin gi", 21, 34, 300, Sex.FEMALE, 3, 60),
            new Band("Veteranos M Sin gi", 35, 60, 240, Sex.MALE, 5, 85));
    static final int MATS = 3;
    static final List<String> CLUBS = List.of("Club Demo Grappling", "Escuela de Lucha Norte", "Gimnasio Sur BJJ");

    private static final List<String> WOMEN = List.of("Lucía", "Martina", "Sofía", "Julia", "Paula", "Alba", "Noa");
    private static final List<String> MEN =
            List.of("Hugo", "Mateo", "Leo", "Daniel", "Pablo", "Álvaro", "Manuel", "Adrián", "Mario", "Diego");
    private static final List<String> LAST_NAMES = List.of(
            "García", "Martín", "López", "Sánchez", "Pérez", "Gómez", "Ruiz", "Díaz", "Moreno", "Muñoz", "Romero",
            "Navarro", "Torres", "Vázquez", "Ramos", "Gil", "Serrano", "Molina");

    private final VerifiedAccounts accounts;
    private final NewEventService newEvents;
    private final EventStaffRepository staff;
    private final MatRepository mats;
    private final EventCategoryRepository categories;
    private final OrganizationRepository clubs;
    private final EventOrganizationRepository eventClubs;
    private final ParticipantRepository participants;

    GrapplingScenario(
            VerifiedAccounts accounts,
            NewEventService newEvents,
            EventStaffRepository staff,
            MatRepository mats,
            EventCategoryRepository categories,
            OrganizationRepository clubs,
            EventOrganizationRepository eventClubs,
            ParticipantRepository participants) {
        this.accounts = accounts;
        this.newEvents = newEvents;
        this.staff = staff;
        this.mats = mats;
        this.categories = categories;
        this.clubs = clubs;
        this.eventClubs = eventClubs;
        this.participants = participants;
    }

    @Override
    public String name() {
        return "grappling";
    }

    @Override
    public String description() {
        return "FELODA grappling event today: club1, ayudante1, arbitro1-" + MATS + " (password = username), "
                + MATS + " mats, " + CATEGORIES.size() + " categories from U13 to veterans, gi and no-gi, "
                + CATEGORIES.stream().mapToInt(Band::size).sum() + " fictitious participants";
    }

    @Override
    public void seed(ScenarioContext ctx) {
        var now = ctx.now().toInstant();
        var club = accounts.club("club1", CLUBS.getFirst(), "G12345674");
        // No mats here: they come below, each with its referee.
        var eventId = newEvents
                .create(club, new NewEventRequest("Open de Grappling", ctx.today(), Discipline.GRAPPLING, 0))
                .eventId();
        staff.save(new EventStaff(eventId, accounts.helper("ayudante1"), EventRole.GROUPER));
        for (int number = 1; number <= MATS; number++) {
            var referee = accounts.helper("arbitro" + number);
            staff.save(new EventStaff(eventId, referee, EventRole.REFEREE));
            mats.save(new Mat(eventId, number, referee));
        }
        var clubIds = CLUBS.stream()
                .map(name -> eventClubs
                        .save(new EventOrganization(eventId, clubs.named(club, name, null, now)))
                        .getId())
                .toList();
        var random = new Random(2026);
        for (var band : CATEGORIES) {
            var category = new EventCategory(eventId, band.name(), band.minAge(), band.maxAge());
            category.setMatchSeconds(band.matchSeconds());
            var categoryId = categories.save(category).getId();
            for (int i = 0; i < band.size(); i++) {
                participants.save(participant(ctx, eventId, categoryId, band, clubIds, random));
            }
        }
    }

    private static Participant participant(
            ScenarioContext ctx, UUID eventId, UUID categoryId, Band band, List<UUID> clubIds, Random random) {
        var sex = band.sex() != null ? band.sex() : random.nextBoolean() ? Sex.FEMALE : Sex.MALE;
        var names = sex == Sex.FEMALE ? WOMEN : MEN;
        var age = band.minAge() + random.nextInt(band.maxAge() - band.minAge() + 1);
        var participant = new Participant(eventId, ctx.now().toInstant());
        participant.update(
                names.get(random.nextInt(names.size())),
                LAST_NAMES.get(random.nextInt(LAST_NAMES.size())) + " "
                        + LAST_NAMES.get(random.nextInt(LAST_NAMES.size())),
                ctx.today().minusYears(age).minusDays(random.nextInt(360)),
                null,
                true,
                categoryId);
        participant.setSex(sex);
        participant.measure(null, BigDecimal.valueOf(band.weightKg() - random.nextInt(5)));
        // About one in four comes without a club.
        var club = random.nextInt(clubIds.size() + 1);
        participant.setOrganizationId(club < clubIds.size() ? clubIds.get(club) : null);
        return participant;
    }

    record Band(String name, int minAge, int maxAge, int matchSeconds, Sex sex, int size, int weightKg) {}
}
