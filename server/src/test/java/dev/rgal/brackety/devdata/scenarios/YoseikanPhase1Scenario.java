package dev.rgal.brackety.devdata.scenarios;

import dev.rgal.brackety.demo.DemoSetup;
import dev.rgal.brackety.devdata.DevScenario;
import dev.rgal.brackety.devdata.Scenario;
import dev.rgal.brackety.devdata.ScenarioContext;
import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventOrganization;
import dev.rgal.brackety.event.EventOrganizationRepository;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.util.List;
import java.util.Random;

@DevScenario
class YoseikanPhase1Scenario implements Scenario {

    static final int PARTICIPANTS = 60;
    // Enough 15-16 year olds for groups of 4 teams of 3 in that team category, plus some left over.
    static final int TEENS = 15;
    // Clubs taking part besides the demo ones; about one in five participants comes without a club.
    static final List<String> MORE_CLUBS = List.of("Club Yoseikan Norte", "Asociación Budo Levante");
    // One without height every this many: the group builder sorts them last.
    static final int NO_HEIGHT_EVERY = 13;

    private static final List<String> FIRST_NAMES = List.of(
            "Lucía", "Hugo", "Martina", "Mateo", "Sofía", "Leo", "Julia", "Daniel", "Paula", "Pablo", "Valeria",
            "Álvaro", "Emma", "Manuel", "Carla", "Adrián", "Noa", "Mario", "Alba", "Diego");
    private static final List<String> LAST_NAMES = List.of(
            "García",
            "Martín",
            "López",
            "Sánchez",
            "Pérez",
            "Gómez",
            "Ruiz",
            "Díaz",
            "Moreno",
            "Muñoz",
            "Romero",
            "Navarro",
            "Torres",
            "Domínguez",
            "Vázquez",
            "Ramos",
            "Gil",
            "Serrano",
            "Molina",
            "Ortega");
    // Ages weighted towards children, as in the real league.
    private static final int[] AGES = {4, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 12, 13, 14, 15, 17, 22, 30};

    private final DemoSetup demo;
    private final ParticipantRepository participants;
    private final EventOrganizationRepository organizations;
    private final EventCategoryRepository categories;

    YoseikanPhase1Scenario(
            DemoSetup demo,
            ParticipantRepository participants,
            EventOrganizationRepository organizations,
            EventCategoryRepository categories) {
        this.demo = demo;
        this.participants = participants;
        this.organizations = organizations;
        this.categories = categories;
    }

    @Override
    public String name() {
        return "yoseikan-f1";
    }

    @Override
    public String description() {
        return "Phase 1 prototype: club1, ayudante1-2, arbitro1-5 (password = username), event today with 5 mats and "
                + (PARTICIPANTS + TEENS + 2) + " fictitious participants (" + TEENS
                + " in the 15-16 team category) from "
                + (DemoSetup.ORGANIZATIONS.size() + MORE_CLUBS.size()) + " clubs, some without club or height";
    }

    @Override
    public void seed(ScenarioContext ctx) {
        var eventId = demo.seed();
        for (var name : MORE_CLUBS) {
            organizations.save(new EventOrganization(eventId, name, null));
        }
        var clubs = organizations.findByEventIdOrderByName(eventId);
        var random = new Random(2027);
        for (int i = 0; i < PARTICIPANTS + TEENS; i++) {
            var age = i < PARTICIPANTS ? AGES[i % AGES.length] : 15;
            var participant = new Participant(eventId, ctx.now().toInstant());
            participant.update(
                    FIRST_NAMES.get(random.nextInt(FIRST_NAMES.size())),
                    LAST_NAMES.get(random.nextInt(LAST_NAMES.size())) + " "
                            + LAST_NAMES.get(random.nextInt(LAST_NAMES.size())),
                    ctx.today().minusYears(age).minusDays(random.nextInt(360)),
                    i % NO_HEIGHT_EVERY == 5 ? null : Math.min(195, 95 + age * 6 + random.nextInt(15)),
                    true);
            var club = random.nextInt(clubs.size() + 1);
            participant.setOrganizationId(club < clubs.size() ? clubs.get(club).getId() : null);
            participants.save(participant);
        }
        // Edge cases: a long name for the lists and CSVs, and an 8 year old fighting up in 9-10.
        var longName = new Participant(eventId, ctx.now().toInstant());
        longName.update(
                "María de los Ángeles",
                "Fernández-Villaverde de la Concepción",
                ctx.today().minusYears(10).minusDays(40),
                138,
                true);
        longName.setOrganizationId(clubs.getFirst().getId());
        participants.save(longName);
        var older = categories.findByEventIdOrderByMinAge(eventId).stream()
                .filter(c -> c.getName().equals("9-10"))
                .map(EventCategory::getId)
                .findFirst()
                .orElseThrow();
        var fightingUp = new Participant(eventId, ctx.now().toInstant());
        fightingUp.update("Íñigo", "Ortega Gil", ctx.today().minusYears(8).minusDays(100), 132, true, older);
        participants.save(fightingUp);
    }
}
