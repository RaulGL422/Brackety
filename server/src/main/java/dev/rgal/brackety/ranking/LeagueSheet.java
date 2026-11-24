package dev.rgal.brackety.ranking;

import static dev.rgal.brackety.ranking.ExportField.number;
import static dev.rgal.brackety.ranking.ExportField.text;

import dev.rgal.brackety.event.EventRepository;
import dev.rgal.brackety.ranking.dto.LeagueStandings.PhasePoints;
import dev.rgal.brackety.ranking.dto.LeagueStandings.Row;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Function;
import org.springframework.stereotype.Component;

/** Clasificación de la liga: one row per person, ranked inside their category, with three columns per phase. */
@Component
class LeagueSheet implements Sheet<Row> {

    private final LeagueStandingsService leagueStandings;
    private final EventRepository events;

    LeagueSheet(LeagueStandingsService leagueStandings, EventRepository events) {
        this.leagueStandings = leagueStandings;
        this.events = events;
    }

    @Override
    public String key() {
        return "league";
    }

    @Override
    public String fileName() {
        return "clasificacion-liga";
    }

    @Override
    public String es() {
        return "Clasificación de la liga";
    }

    @Override
    public String en() {
        return "League standings";
    }

    @Override
    public List<ExportField<Row>> fields(SheetData data) {
        var fields = new ArrayList<ExportField<Row>>(List.of(
                text("category", "Categoría", "Category", Row::categoryName),
                // With 0 points nobody has a place yet (the app shows a dash too).
                number("position", "Posición", "Position", r -> r.total() > 0 ? r.position() : null),
                text("medal", "Medalla", "Medal", r -> SheetText.medal(r.medal())),
                text("firstName", "Nombre", "First name", Row::firstName),
                text("lastName", "Apellidos", "Last name", Row::lastName),
                text("club", "Club", "Club", Row::organizationName)));
        var phases = events.findByLeagueIdOrderByPhaseNumber(data.event().getLeagueId());
        for (int i = 0; i < phases.size(); i++) {
            var n = phases.get(i).getPhaseNumber();
            var index = i;
            Function<Row, PhasePoints> phase = r -> r.phases().get(index);
            fields.add(text(
                    "phase" + n + "Attendance",
                    "Fase " + n + ": asistencia",
                    "Phase " + n + ": attendance",
                    r -> phase.apply(r) == null ? "No inscrito" : phase.apply(r).attendancePoints()));
            fields.add(number(
                    "phase" + n + "MatchPoints",
                    "Fase " + n + ": puntos en combates",
                    "Phase " + n + ": match points",
                    r -> phase.apply(r) == null ? null : phase.apply(r).matchPoints()));
            fields.add(number(
                    "phase" + n + "Total",
                    "Fase " + n + ": total",
                    "Phase " + n + ": total",
                    r -> phase.apply(r) == null ? null : phase.apply(r).total()));
        }
        fields.add(number("leagueTotal", "Total liga", "League total", Row::total));
        fields.add(number("warnings", "Advertencias en la liga", "Warnings in the league", Row::warnings));
        fields.add(number(
                "disqualifications",
                "Descalificaciones en la liga",
                "Disqualifications in the league",
                Row::disqualifications));
        return fields;
    }

    @Override
    public List<Row> rows(SheetData data) {
        return leagueStandings.of(data.event()).rows();
    }
}
