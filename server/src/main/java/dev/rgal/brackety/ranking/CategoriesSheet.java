package dev.rgal.brackety.ranking;

import static dev.rgal.brackety.ranking.ExportField.number;
import static dev.rgal.brackety.ranking.ExportField.text;

import dev.rgal.brackety.event.EventCategory;
import dev.rgal.brackety.grouping.FightGroup;
import dev.rgal.brackety.league.Podium;
import java.util.HashMap;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/** Categorías: how each one is set up, how many entered and its podium in the league. */
@Component
class CategoriesSheet implements Sheet<CategoriesSheet.Row> {

    record Row(EventCategory category, int entered, long groups, Podium podium) {}

    private static final List<ExportField<Row>> FIELDS = List.of(
            text("category", "Categoría", "Category", r -> r.category().getName()),
            number("minAge", "Edad mínima", "Minimum age", r -> r.category().getMinAge()),
            number("maxAge", "Edad máxima", "Maximum age", r -> r.category().getMaxAge()),
            text(
                    "format",
                    "Formato",
                    "Format",
                    r -> r.category().getFormat() == EventCategory.Format.TEAM ? "Por equipos" : "Individual"),
            number(
                    "teamSize",
                    "Alumnos por equipo",
                    "Members per team",
                    r -> r.category().getTeamSize()),
            text("groupSize", "Por grupo (alumnos o equipos)", "Per group (students or teams)", r -> {
                var c = r.category();
                return c.getMinGroupSize() == c.getMaxGroupSize()
                        ? String.valueOf(c.getMaxGroupSize())
                        : c.getMinGroupSize() + " a " + c.getMaxGroupSize();
            }),
            text("returnLeg", "Ida y vuelta", "Return leg", r -> r.category().isReturnLeg() ? "Sí" : "No"),
            number("entered", "Inscritos", "Entered", Row::entered),
            number("groups", "Grupos", "Groups", Row::groups),
            number(
                    "podiumFirsts",
                    "Podio: primeros",
                    "Podium: firsts",
                    r -> r.podium().firsts()),
            number(
                    "podiumSeconds",
                    "Podio: segundos",
                    "Podium: seconds",
                    r -> r.podium().seconds()),
            number(
                    "podiumThirds",
                    "Podio: terceros",
                    "Podium: thirds",
                    r -> r.podium().thirds()));

    private final LeagueStandingsService leagueStandings;

    CategoriesSheet(LeagueStandingsService leagueStandings) {
        this.leagueStandings = leagueStandings;
    }

    @Override
    public String key() {
        return "categories";
    }

    @Override
    public String fileName() {
        return "categorias";
    }

    @Override
    public String es() {
        return "Categorías";
    }

    @Override
    public String en() {
        return "Categories";
    }

    @Override
    public List<ExportField<Row>> fields(SheetData data) {
        return FIELDS;
    }

    @Override
    public List<Row> rows(SheetData d) {
        var podiums = leagueStandings.podiums(d.event().getLeagueId());
        var entered = new HashMap<UUID, Integer>();
        for (var p : d.participants()) {
            p.categoryIn(d.event(), d.categories()).ifPresent(c -> entered.merge(c.getId(), 1, Integer::sum));
        }
        var groupCount = d.groups().values().stream()
                .collect(Collectors.groupingBy(FightGroup::getCategoryId, Collectors.counting()));
        return d.categories().stream()
                .map(c -> new Row(
                        c,
                        entered.getOrDefault(c.getId(), 0),
                        groupCount.getOrDefault(c.getId(), 0L),
                        podiums.of(c.getName())))
                .toList();
    }
}
