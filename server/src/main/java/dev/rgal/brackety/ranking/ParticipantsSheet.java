package dev.rgal.brackety.ranking;

import static dev.rgal.brackety.ranking.ExportField.number;
import static dev.rgal.brackety.ranking.ExportField.text;

import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.grouping.FightGroup;
import dev.rgal.brackety.participant.Participant;
import dev.rgal.brackety.participant.ParticipantService;
import dev.rgal.brackety.ranking.ExportField.Kind;
import dev.rgal.brackety.ranking.ExportField.Sensitivity;
import java.util.HashMap;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Component;

/** Inscritos: one row per participant, by name. */
@Component
class ParticipantsSheet implements Sheet<ParticipantsSheet.Row> {

    record Row(Participant person, int age, String category, String team, FightGroup group, Integer mat, String club) {}

    private static final List<ExportField<Row>> FIELDS = List.of(
            text("firstName", "Nombre", "First name", r -> r.person().getFirstName()),
            text("lastName", "Apellidos", "Last name", r -> r.person().getLastName()),
            ExportField.<Row>of(
                            "birthDate",
                            "Fecha de nacimiento",
                            "Date of birth",
                            Kind.DATE,
                            r -> r.person().getBirthDate())
                    .as(Sensitivity.PERSONAL),
            ExportField.<Row>number("age", "Edad el día del evento", "Age on the event day", Row::age)
                    .as(Sensitivity.PERSONAL),
            text("sex", "Sexo", "Sex", r -> SheetText.sex(r.person().getSex())),
            ExportField.<Row>number(
                            "heightCm",
                            "Estatura (cm)",
                            "Height (cm)",
                            r -> r.person().getHeightCm())
                    .as(Sensitivity.PERSONAL),
            ExportField.<Row>of(
                            "weightKg",
                            "Peso (kg)",
                            "Weight (kg)",
                            Kind.DECIMAL,
                            r -> r.person().getWeightKg())
                    .as(Sensitivity.PERSONAL),
            text("club", "Club", "Club", Row::club),
            text("category", "Categoría", "Category", Row::category),
            text(
                    "categoryChoice",
                    "Cómo se asignó la categoría",
                    "How the category was set",
                    r -> r.person().getCategoryId() == null ? "Por edad" : "Elegida a mano"),
            ExportField.<Row>text(
                            "guardianConsent",
                            "Consentimiento del tutor",
                            "Guardian's consent",
                            r -> r.age() < ParticipantService.ADULT_AGE
                                    ? (r.person().hasGuardianConsent() ? "Sí" : "Falta")
                                    : "No hace falta (adulto)")
                    .as(Sensitivity.MINORS),
            text("team", "Equipo", "Team", Row::team),
            number(
                    "group",
                    "Grupo",
                    "Group",
                    r -> r.group() == null ? null : r.group().getNumber()),
            number("mat", "Tapiz", "Mat", Row::mat),
            text(
                    "personId",
                    "Id de la persona (igual en todas las fases)",
                    "Person id (the same in every phase)",
                    r -> r.person().getPersonId()));

    @Override
    public String key() {
        return "participants";
    }

    @Override
    public String fileName() {
        return "participantes";
    }

    @Override
    public String es() {
        return "Inscritos";
    }

    @Override
    public String en() {
        return "Participants";
    }

    @Override
    public List<ExportField<Row>> fields(SheetData data) {
        return FIELDS;
    }

    @Override
    public List<Row> rows(SheetData d) {
        var groupOf = new HashMap<UUID, FightGroup>();
        var teamGroups = new HashMap<UUID, FightGroup>();
        for (var m : d.members()) {
            if (m.isGhost()) {
                continue;
            }
            if (m.getTeamId() != null) {
                teamGroups.put(m.getTeamId(), d.groups().get(m.getGroupId()));
            } else {
                groupOf.put(m.getParticipantId(), d.groups().get(m.getGroupId()));
            }
        }
        var teamIdByNumber = new HashMap<Integer, UUID>();
        for (var m : d.members()) {
            var c = m.getTeamId() == null ? null : d.competitors().get(m.getTeamId());
            if (c != null) {
                teamIdByNumber.put(c.teamNumber(), c.id());
            }
        }
        return d.participants().stream()
                .map(p -> {
                    var team = d.teamNumbers().get(p.getId());
                    var group = groupOf.get(p.getId());
                    if (group == null && team != null) {
                        group = teamGroups.get(teamIdByNumber.get(team));
                    }
                    return new Row(
                            p,
                            d.event().ageOf(p.getBirthDate()),
                            p.categoryIn(d.event(), d.categories())
                                    .map(EventCategory::getName)
                                    .orElse("Sin categoría"),
                            team == null ? null : "Equipo " + team,
                            group,
                            group == null ? null : d.matNumbers().get(group.getMatId()),
                            d.organizationNames().get(p.getOrganizationId()));
                })
                .toList();
    }
}
