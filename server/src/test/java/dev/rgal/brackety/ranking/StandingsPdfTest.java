package dev.rgal.brackety.ranking;

import static org.assertj.core.api.Assertions.assertThat;

import dev.rgal.brackety.ranking.dto.LeagueStandings;
import dev.rgal.brackety.ranking.dto.LeagueStandings.PhasePoints;
import dev.rgal.brackety.ranking.dto.LeagueStandings.Row;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;
import org.openpdf.text.pdf.PdfReader;
import org.openpdf.text.pdf.parser.PdfTextExtractor;

class StandingsPdfTest {

    @Test
    void eachCategoryOnItsOwnPageWithItsTableAndPageNumbers() throws Exception {
        var standings = standings(
                2,
                row("9-10", 1, 1, "Ana", 13, new PhasePoints(10, 3), null),
                row("9-10", 2, 2, "Bea", 11, new PhasePoints(10, 1), null),
                row("11-12", 1, null, "Cris", 0, null, new PhasePoints(0, 0)));

        var reader = new PdfReader(
                StandingsPdf.of(standings, "Liga Yoseikan · Fase 2 · 24/01/2027", "24/01/2027 a las 18:00"));
        var text = new PdfTextExtractor(reader);

        assertThat(reader.getNumberOfPages()).isEqualTo(2);
        assertThat(text.getTextFromPage(1))
                .contains("9-10", "Liga Yoseikan · Fase 2", "Pos.", "Fase 1", "Fase 2", "Total")
                .contains("Ana Prueba", "Oro (1.º)", "Plata (2.º)", "Club Demo")
                .contains("Generado el 24/01/2027 a las 18:00", "Página 1 de 2")
                .doesNotContain("Cris");
        // With 0 points nobody has a place yet.
        assertThat(text.getTextFromPage(2)).contains("11-12", "Cris Prueba", "–", "Página 2 de 2");
        assertThat(reader.getPageSizeWithRotation(1).getWidth())
                .isLessThan(reader.getPageSizeWithRotation(1).getHeight());
    }

    @Test
    void manyPhasesTurnThePageAndNoRowsStillMakeAPage() throws Exception {
        var phases = new PhasePoints[5];
        Arrays.fill(phases, new PhasePoints(10, 0));
        var wide = new PdfReader(StandingsPdf.of(standings(5, row("9-10", 1, 1, "Ana", 50, phases)), "Liga", "hoy"));
        assertThat(wide.getPageSizeWithRotation(1).getWidth())
                .isGreaterThan(wide.getPageSizeWithRotation(1).getHeight());

        var empty = new PdfReader(StandingsPdf.of(standings(1), "Liga", "hoy"));
        assertThat(new PdfTextExtractor(empty).getTextFromPage(1)).contains("Todavía no hay nadie");
    }

    private static LeagueStandings standings(int phaseCount, Row... rows) {
        var phases = IntStream.rangeClosed(1, phaseCount)
                .mapToObj(n -> new LeagueStandings.Phase(UUID.randomUUID(), n, "Fase " + n))
                .toList();
        return new LeagueStandings(phases, List.of(rows));
    }

    private static Row row(
            String category, int position, Integer medal, String name, int total, PhasePoints... phases) {
        return new Row(
                category,
                position,
                medal,
                UUID.randomUUID(),
                name,
                "Prueba",
                "Club Demo",
                new ArrayList<>(Arrays.asList(phases)),
                total,
                0,
                0,
                UUID.randomUUID(),
                UUID.randomUUID());
    }
}
