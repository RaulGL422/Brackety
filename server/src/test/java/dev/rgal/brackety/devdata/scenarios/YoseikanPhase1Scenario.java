package dev.rgal.brackety.devdata.scenarios;

import dev.rgal.brackety.demo.DemoSetup;
import dev.rgal.brackety.devdata.DevScenario;
import dev.rgal.brackety.devdata.Scenario;
import dev.rgal.brackety.devdata.ScenarioContext;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantRepository;
import java.util.List;
import java.util.Random;

@DevScenario
class YoseikanPhase1Scenario implements Scenario {

    static final int PARTICIPANTS = 60;

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

    YoseikanPhase1Scenario(DemoSetup demo, ParticipantRepository participants) {
        this.demo = demo;
        this.participants = participants;
    }

    @Override
    public String name() {
        return "yoseikan-f1";
    }

    @Override
    public String description() {
        return "Phase 1 prototype: club1, ayudante1-2, arbitro1-5 (password = username), event today with 5 mats and "
                + PARTICIPANTS + " fictitious participants";
    }

    @Override
    public void seed(ScenarioContext ctx) {
        var eventId = demo.seed();
        var random = new Random(2027);
        for (int i = 0; i < PARTICIPANTS; i++) {
            var age = AGES[i % AGES.length];
            var participant = new Participant(eventId, ctx.now().toInstant());
            participant.update(
                    FIRST_NAMES.get(random.nextInt(FIRST_NAMES.size())),
                    LAST_NAMES.get(random.nextInt(LAST_NAMES.size())) + " "
                            + LAST_NAMES.get(random.nextInt(LAST_NAMES.size())),
                    ctx.today().minusYears(age).minusDays(random.nextInt(360)),
                    Math.min(195, 95 + age * 6 + random.nextInt(15)),
                    true);
            participants.save(participant);
        }
    }
}
