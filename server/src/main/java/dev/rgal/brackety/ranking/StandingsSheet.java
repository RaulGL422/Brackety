package dev.rgal.brackety.ranking;

import static dev.rgal.brackety.ranking.ExportField.number;
import static dev.rgal.brackety.ranking.ExportField.text;

import dev.rgal.brackety.ranking.ExportField.Sensitivity;
import dev.rgal.brackety.ranking.dto.StandingRow;
import java.util.List;
import java.util.Set;
import org.springframework.stereotype.Component;

/** Clasificación de la fase: attendance plus match points, ranked inside each category. */
@Component
class StandingsSheet implements Sheet<StandingRow> {

    // Grappling ranks by wins and classification points: the built-in sheet shows them only when the event has them.
    private static final Set<String> CLASSIFICATION = Set.of("wins", "classificationPoints");

    private static final List<ExportField<StandingRow>> FIELDS = List.of(
            number("position", "Posición", "Position", StandingRow::position),
            number("wins", "Victorias", "Wins", StandingRow::wins),
            number(
                    "classificationPoints",
                    "Puntos de clasificación",
                    "Classification points",
                    StandingRow::classificationPoints),
            text("firstName", "Nombre", "First name", StandingRow::firstName),
            text("lastName", "Apellidos", "Last name", StandingRow::lastName),
            ExportField.<StandingRow>number("age", "Edad el día del evento", "Age on the event day", StandingRow::age)
                    .as(Sensitivity.PERSONAL),
            text("club", "Club", "Club", StandingRow::organizationName),
            text("category", "Categoría", "Category", StandingRow::categoryName),
            text("team", "Equipo", "Team", r -> r.teamNumber() == null ? null : "Equipo " + r.teamNumber()),
            number("attendancePoints", "Puntos de asistencia", "Attendance points", StandingRow::attendancePoints),
            number("matchPoints", "Puntos en combates", "Match points", StandingRow::matchPoints),
            number("total", "Total", "Total", StandingRow::total),
            number("matches", "Combates disputados", "Matches fought", StandingRow::matches));

    private final StandingsService standings;

    StandingsSheet(StandingsService standings) {
        this.standings = standings;
    }

    @Override
    public String key() {
        return "standings";
    }

    @Override
    public String fileName() {
        return "clasificacion-fase";
    }

    @Override
    public String es() {
        return "Clasificación de la fase";
    }

    @Override
    public String en() {
        return "Phase standings";
    }

    @Override
    public List<ExportField<StandingRow>> fields(SheetData data) {
        return FIELDS;
    }

    @Override
    public List<StandingRow> rows(SheetData data) {
        return standings.rows(data.event());
    }

    @Override
    public List<String> builtInColumns(SheetData data, List<StandingRow> rows) {
        var classified = rows.stream().anyMatch(r -> r.wins() != null);
        return FIELDS.stream()
                .map(ExportField::key)
                .filter(key -> classified || !CLASSIFICATION.contains(key))
                .toList();
    }
}
