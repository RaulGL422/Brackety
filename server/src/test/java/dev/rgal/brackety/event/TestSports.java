package dev.rgal.brackety.event;

import dev.rgal.brackety.event.ScoringRules.Action;
import dev.rgal.brackety.event.ScoringRules.Classification;
import dev.rgal.brackety.event.ScoringRules.Tiebreak;
import java.util.List;

/**
 * The rules tambo and grappling had in code before they became sport templates (docs/producto/plantillas-deporte.md):
 * the tests' fixed values, and what the seeded templates must still give ({@code SportTemplatesTest}).
 */
public final class TestSports {

    /** Liga Yoseikan, cap. 3.1, and Raul's rules of the F1 (2026-11-13). */
    public static final ScoringRules TAMBO = new ScoringRules(
            List.of(new Action(1, "Punto")), List.of(0, 1), 0, 0, true, true, true, List.of(), List.of(), List.of());

    /** FELODA national rules, November 2025 (docs/reglamentos/grappling-feloda-2025.md, art. 38). */
    public static final ScoringRules GRAPPLING = new ScoringRules(
            List.of(
                    new Action(1, "Salida o ataque"),
                    new Action(2, "Derribo, inversión o derribo rápido"),
                    new Action(3, "Montada lateral o derribo de amplitud"),
                    new Action(4, "Montada o espalda")),
            List.of(1),
            4,
            15,
            false,
            false,
            false,
            List.of("Sumisión"),
            List.of(Tiebreak.BEST_ACTION, Tiebreak.FEWER_WARNINGS, Tiebreak.EXTRA_TIME),
            List.of(
                    new Classification("SUBMISSION", 5, 0, 0),
                    new Classification("DISQUALIFICATION", 5, 0, 0),
                    new Classification("SUPERIORITY", 4, 0, 1),
                    new Classification("TIME", 3, 0, 1),
                    new Classification("WARNINGS", 3, 0, 0),
                    new Classification("EXTRA_TIME", 2, 0, 0)));

    public static final List<String> TAMBO_WARNINGS = List.of(
            "Proyección o golpeo",
            "Tirarse rodando",
            "Ataque de pique",
            "Exceso de potencia",
            "Conducta antideportiva");

    public static final List<String> GRAPPLING_WARNINGS = List.of(
            "Pasividad",
            "Salir o huir del tapiz",
            "Sentarse a guardia sin contacto",
            "Agarrar la ropa (sin gi)",
            "Heel hook",
            "Neck crank o presión en la columna",
            "Slam",
            "Pequeñas articulaciones o menos de 4 dedos",
            "Dedos en ojos, cara o tráquea",
            "Llave con proyección",
            "Estrangular con el cinturón (gi)",
            "Técnica prohibida en U13 y U15",
            "Ignorar al árbitro o conducta antideportiva");

    private TestSports() {}
}
