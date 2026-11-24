package dev.rgal.brackety.ranking;

import static dev.rgal.brackety.ranking.ExportField.number;
import static dev.rgal.brackety.ranking.ExportField.text;

import dev.rgal.brackety.grouping.Competitor;
import dev.rgal.brackety.grouping.Match;
import dev.rgal.brackety.ranking.ExportField.Kind;
import dev.rgal.brackety.scoreboard.Side;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/** Combates: every match by group and order, with its result. */
@Component
class MatchesSheet implements Sheet<MatchesSheet.Row> {

    record Row(
            Match match,
            int group,
            String category,
            Integer mat,
            Competitor red,
            String redClub,
            Competitor blue,
            String blueClub,
            int pointsLimit,
            String wildcards) {}

    private static final List<ExportField<Row>> FIELDS = List.of(
            number("group", "Grupo", "Group", Row::group),
            text("category", "Categoría", "Category", Row::category),
            number("mat", "Tapiz", "Mat", Row::mat),
            number(
                    "number",
                    "Combate nº (en el grupo)",
                    "Match no. (in the group)",
                    r -> r.match().getOrderIndex() + 1),
            text("red", "Rojo", "Red", r -> SheetText.label(r.red())),
            text("redClub", "Club rojo", "Red's club", Row::redClub),
            text("blue", "Azul", "Blue", r -> SheetText.label(r.blue())),
            text("blueClub", "Club azul", "Blue's club", Row::blueClub),
            number("redPoints", "Puntos rojo", "Red's points", r -> r.match().getRedScore()),
            number("bluePoints", "Puntos azul", "Blue's points", r -> r.match().getBlueScore()),
            text("winner", "Ganador", "Winner", r -> winner(r.match(), r.red(), r.blue())),
            text(
                    "endReason",
                    "Cómo acabó",
                    "How it ended",
                    r -> endReason(r.match(), r.pointsLimit(), r.red(), r.blue())),
            text("status", "Estado", "Status", r -> SheetText.status(r.match().getStatus())),
            text("wildcards", "Comodín del grupo (no puntúa)", "Group's wildcard (does not score)", Row::wildcards),
            ExportField.<Row>of(
                    "date", "Fecha", "Date", Kind.DATE, r -> r.match().getStartedAt()),
            ExportField.<Row>of(
                    "startTime",
                    "Hora de inicio",
                    "Start time",
                    Kind.TIME,
                    r -> r.match().getStartedAt()),
            ExportField.<Row>of(
                    "endTime",
                    "Hora de fin",
                    "End time",
                    Kind.TIME,
                    r -> r.match().getFinishedAt()),
            ExportField.<Row>of(
                    "duration",
                    "Tiempo de combate (m:ss)",
                    "Fight time (m:ss)",
                    Kind.DURATION,
                    r -> r.match().getStartedAt() == null ? null : r.match().getElapsedMs()));

    @Override
    public String key() {
        return "matches";
    }

    @Override
    public String fileName() {
        return "combates";
    }

    @Override
    public String es() {
        return "Combates";
    }

    @Override
    public String en() {
        return "Matches";
    }

    @Override
    public List<ExportField<Row>> fields() {
        return FIELDS;
    }

    @Override
    public List<Row> rows(SheetData d) {
        var ghosts = StandingsService.ghostsByGroup(d.members());
        return d.matches().stream()
                .sorted(Comparator.comparingInt((Match m) -> d.groupNumber(m.getGroupId()))
                        .thenComparingInt(Match::getOrderIndex))
                .map(m -> {
                    var group = d.groups().get(m.getGroupId());
                    var red = d.competitors().get(m.getRedId());
                    var blue = d.competitors().get(m.getBlueId());
                    var ghostNames = ghosts.getOrDefault(m.getGroupId(), Set.of()).stream()
                            .map(d.competitors()::name)
                            .sorted()
                            .collect(Collectors.joining(", "));
                    return new Row(
                            m,
                            group.getNumber(),
                            d.categoryNames().get(group.getCategoryId()),
                            d.matNumbers().get(m.getMatId()),
                            red,
                            d.clubOf(red),
                            blue,
                            d.clubOf(blue),
                            d.event().modality().pointsLimit(m.isTeamMatch()),
                            ghostNames.isEmpty() ? null : ghostNames);
                })
                .toList();
    }

    /** The disqualified side loses; otherwise the higher score. Only for finished matches. */
    static String winner(Match m, Competitor red, Competitor blue) {
        if (m.getStatus() != Match.Status.FINISHED) {
            return null;
        }
        if (m.getDisqualifiedSide() != null) {
            return Side.RED.name().equals(m.getDisqualifiedSide()) ? blue.name() : red.name();
        }
        if (m.getRedScore() == m.getBlueScore()) {
            return "Empate";
        }
        return m.getRedScore() > m.getBlueScore() ? red.name() : blue.name();
    }

    /** {@code pointsLimit}: 0 = no limit. */
    static String endReason(Match m, int pointsLimit, Competitor red, Competitor blue) {
        if (m.getStatus() != Match.Status.FINISHED) {
            return null;
        }
        if (m.getDisqualifiedSide() != null) {
            return "Descalificación de " + (Side.RED.name().equals(m.getDisqualifiedSide()) ? red.name() : blue.name());
        }
        if (pointsLimit > 0 && Math.max(m.getRedScore(), m.getBlueScore()) >= pointsLimit) {
            return "Llegó a " + pointsLimit + " puntos";
        }
        return "Fin del tiempo";
    }
}
