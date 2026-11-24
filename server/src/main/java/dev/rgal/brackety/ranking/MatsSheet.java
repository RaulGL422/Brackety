package dev.rgal.brackety.ranking;

import static dev.rgal.brackety.ranking.ExportField.number;
import static dev.rgal.brackety.ranking.ExportField.text;

import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.grouping.Match;
import java.util.List;
import org.springframework.stereotype.Component;

/** Tapices: each mat, its referee and how far its matches went. */
@Component
class MatsSheet implements Sheet<MatsSheet.Row> {

    record Row(int number, String referee, long groups, int matches, long finished) {}

    private static final List<ExportField<Row>> FIELDS = List.of(
            number("mat", "Tapiz", "Mat", Row::number),
            text("referee", "Árbitro (usuario)", "Referee (username)", Row::referee),
            number("groups", "Grupos", "Groups", Row::groups),
            number("matches", "Combates", "Matches", Row::matches),
            number("finished", "Combates terminados", "Finished matches", Row::finished));

    private final SheetSource source;

    MatsSheet(SheetSource source) {
        this.source = source;
    }

    @Override
    public String key() {
        return "mats";
    }

    @Override
    public String fileName() {
        return "tapices";
    }

    @Override
    public String es() {
        return "Tapices";
    }

    @Override
    public String en() {
        return "Mats";
    }

    @Override
    public List<ExportField<Row>> fields() {
        return FIELDS;
    }

    @Override
    public List<Row> rows(SheetData d) {
        var referees = source.usernames(d.mats().stream().map(Mat::getRefereeAccountId));
        return d.mats().stream()
                .map(mat -> {
                    var mine = d.matches().stream()
                            .filter(m -> mat.getId().equals(m.getMatId()))
                            .toList();
                    return new Row(
                            mat.getNumber(),
                            referees.getOrDefault(mat.getRefereeAccountId(), "Sin árbitro"),
                            d.groups().values().stream()
                                    .filter(g -> mat.getId().equals(g.getMatId()))
                                    .count(),
                            mine.size(),
                            mine.stream()
                                    .filter(m -> m.getStatus() == Match.Status.FINISHED)
                                    .count());
                })
                .toList();
    }
}
