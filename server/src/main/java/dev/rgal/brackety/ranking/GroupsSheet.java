package dev.rgal.brackety.ranking;

import static dev.rgal.brackety.ranking.ExportField.number;
import static dev.rgal.brackety.ranking.ExportField.text;

import dev.rgal.brackety.grouping.Competitor;
import dev.rgal.brackety.grouping.FightGroup;
import dev.rgal.brackety.grouping.GroupMember;
import dev.rgal.brackety.ranking.ExportField.Kind;
import java.util.Comparator;
import java.util.List;
import org.springframework.stereotype.Component;

/** Grupos: one row per group member, in the order of the group. */
@Component
class GroupsSheet implements Sheet<GroupsSheet.Row> {

    record Row(
            FightGroup group,
            String category,
            Integer mat,
            String createdBy,
            GroupMember member,
            Competitor competitor,
            String club) {}

    private static final List<ExportField<Row>> FIELDS = List.of(
            number("group", "Grupo", "Group", r -> r.group().getNumber()),
            text("category", "Categoría", "Category", Row::category),
            number("mat", "Tapiz", "Mat", Row::mat),
            ExportField.<Row>of(
                    "createdAt",
                    "Creado",
                    "Created",
                    Kind.DATE_TIME,
                    r -> r.group().getCreatedAt()),
            text("createdBy", "Creado por", "Created by", Row::createdBy),
            number(
                    "position",
                    "Orden en el grupo",
                    "Order in the group",
                    r -> r.member().getPosition() + 1),
            text(
                    "competitor",
                    "Alumno o equipo",
                    "Student or team",
                    r -> r.competitor().name()),
            text(
                    "teamMembers",
                    "Miembros del equipo",
                    "Team members",
                    r -> r.competitor().isTeam()
                            ? String.join(", ", r.competitor().memberNames())
                            : null),
            text("club", "Club", "Club", Row::club),
            text("wildcard", "Comodín", "Wildcard", r -> r.member().isGhost() ? "Sí (combate, no puntúa)" : "No"));

    private final SheetSource source;

    GroupsSheet(SheetSource source) {
        this.source = source;
    }

    @Override
    public String key() {
        return "groups";
    }

    @Override
    public String fileName() {
        return "grupos";
    }

    @Override
    public String es() {
        return "Grupos";
    }

    @Override
    public String en() {
        return "Groups";
    }

    @Override
    public List<ExportField<Row>> fields(SheetData data) {
        return FIELDS;
    }

    @Override
    public List<Row> rows(SheetData d) {
        var creators = source.usernames(d.groups().values().stream().map(FightGroup::getCreatedBy));
        return d.members().stream()
                .sorted(Comparator.comparingInt((GroupMember m) -> d.groupNumber(m.getGroupId()))
                        .thenComparingInt(GroupMember::getPosition))
                .map(m -> {
                    var g = d.groups().get(m.getGroupId());
                    var c = d.competitors().get(m.getCompetitorId());
                    return new Row(
                            g,
                            d.categoryNames().get(g.getCategoryId()),
                            d.matNumbers().get(g.getMatId()),
                            creators.get(g.getCreatedBy()),
                            m,
                            c,
                            d.clubOf(c));
                })
                .toList();
    }
}
