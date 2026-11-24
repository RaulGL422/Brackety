package dev.rgal.brackety.ranking;

import static dev.rgal.brackety.ranking.ExportField.number;
import static dev.rgal.brackety.ranking.ExportField.text;

import dev.rgal.brackety.grouping.Match;
import dev.rgal.brackety.ranking.ExportField.Kind;
import dev.rgal.brackety.scoreboard.MatchEvent;
import dev.rgal.brackety.scoreboard.MatchEventRepository;
import dev.rgal.brackety.scoreboard.Side;
import java.time.Duration;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/** Línea de tiempo: every referee action of every match, in order, as the club reviews it. */
@Component
class TimelineSheet implements Sheet<TimelineSheet.Row> {

    record Row(
            MatchEvent action,
            Match match,
            int group,
            Integer mat,
            int position,
            String fighter,
            String reason,
            String user,
            Integer undoes,
            boolean undone) {}

    private static final List<ExportField<Row>> FIELDS = List.of(
            number("group", "Grupo", "Group", Row::group),
            number(
                    "match",
                    "Combate nº (en el grupo)",
                    "Match no. (in the group)",
                    r -> r.match().getOrderIndex() + 1),
            number("mat", "Tapiz", "Mat", Row::mat),
            number("position", "Acción nº", "Action no.", Row::position),
            ExportField.<Row>of(
                    "date", "Fecha", "Date", Kind.DATE, r -> r.action().getAt()),
            ExportField.<Row>of(
                    "time", "Hora", "Time", Kind.TIME, r -> r.action().getAt()),
            ExportField.<Row>of(
                    "clock",
                    "Reloj del combate (m:ss)",
                    "Match clock (m:ss)",
                    Kind.DURATION,
                    r -> r.action().getClockMs()),
            text(
                    "action",
                    "Acción",
                    "Action",
                    r -> SheetText.action(
                            r.action().getType().name(), r.action().getPoints())),
            text(
                    "side",
                    "Lado",
                    "Side",
                    r -> SheetText.side(
                            r.action().getSide() == null
                                    ? null
                                    : r.action().getSide().name())),
            text("fighter", "Alumno o equipo", "Student or team", Row::fighter),
            text("reason", "Motivo", "Reason", Row::reason),
            text("user", "Usuario", "User", Row::user),
            text("undo", "Deshacer", "Undo", r -> r.undoes() == null ? null : "Deshace la acción " + r.undoes()),
            text("undone", "Deshecha después", "Undone later", r -> r.undone() ? "Sí" : "No"));

    private final MatchEventRepository matchEvents;
    private final SheetSource source;

    TimelineSheet(MatchEventRepository matchEvents, SheetSource source) {
        this.matchEvents = matchEvents;
        this.source = source;
    }

    @Override
    public String key() {
        return "timeline";
    }

    @Override
    public String fileName() {
        return "linea-de-tiempo";
    }

    @Override
    public String es() {
        return "Línea de tiempo";
    }

    @Override
    public String en() {
        return "Timeline";
    }

    @Override
    public List<ExportField<Row>> fields(SheetData data) {
        return FIELDS;
    }

    @Override
    public List<Row> rows(SheetData d) {
        var matchById = d.matches().stream().collect(Collectors.toMap(Match::getId, Function.identity()));
        var history = matchEvents.findByEventId(d.event().getId());
        var actors = source.usernames(history.stream().map(MatchEvent::getActorAccountId));
        var positions = new HashMap<UUID, Integer>();
        var counters = new HashMap<UUID, Integer>();
        for (var e : history) {
            positions.put(e.getId(), counters.merge(e.getMatchId(), 1, Integer::sum));
        }
        var undone = history.stream()
                .map(MatchEvent::getTargetEventId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        return history.stream()
                .sorted(Comparator.comparingInt((MatchEvent e) ->
                                d.groupNumber(matchById.get(e.getMatchId()).getGroupId()))
                        .thenComparingInt(e -> matchById.get(e.getMatchId()).getOrderIndex())
                        .thenComparingInt(e -> positions.get(e.getId())))
                .map(e -> {
                    var m = matchById.get(e.getMatchId());
                    var length = Duration.ofSeconds(d.event().modality().matchSeconds(m.isTeamMatch()));
                    return new Row(
                            e,
                            m,
                            d.groupNumber(m.getGroupId()),
                            d.matNumbers().get(m.getMatId()),
                            positions.get(e.getId()),
                            e.getSide() == null
                                    ? null
                                    : d.competitors().name(e.getSide() == Side.RED ? m.getRedId() : m.getBlueId()),
                            e.getDeltaMs() != null
                                    ? SheetText.clockAdjust(e.getDeltaMs())
                                    : e.isOvertimePoint(length) ? "Fuera de tiempo" : e.getReason(),
                            e.isAutomatic() ? "Automático" : actors.get(e.getActorAccountId()),
                            e.getTargetEventId() == null ? null : positions.get(e.getTargetEventId()),
                            undone.contains(e.getId()));
                })
                .toList();
    }
}
