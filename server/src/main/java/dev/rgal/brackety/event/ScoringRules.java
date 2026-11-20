package dev.rgal.brackety.event;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import java.util.List;

/**
 * How a sport scores a match, as data: each modality keeps its own copy, so an event never changes when a sport's
 * defaults do. The sport templates (docs/producto/plantillas-deporte.md) will be stored sets of these; for now the
 * built-in ones are {@link #TAMBO} and {@link #GRAPPLING}.
 *
 * @param actions the scoring buttons of the referee, each with its points
 * @param warningsPerRivalPoint every this many warnings of a fighter, the rival gets a point
 * @param warningsToDisqualify the warning that disqualifies; 0 = none
 * @param superiorityGap the points difference that ends the match; 0 = none
 * @param pointsAfterTime the last action's point still counts once the clock shows 0:00
 * @param disqualificationScores a disqualification scores 0 for the disqualified and the limit for the rival
 * @param oneHandWarnings the one-hand warning exists (tambo, ages 4 to 8)
 * @param submissions a submission ends the match
 * @param tiebreaks a tie on points is broken by the best action, how many of it, fewer warnings, then extra time
 */
public record ScoringRules(
        @NotEmpty @Size(max = 10) List<@Valid Action> actions,
        @Min(1) @Max(10) int warningsPerRivalPoint,
        @Min(0) @Max(10) int warningsToDisqualify,
        @Min(0) @Max(100) int superiorityGap,
        boolean pointsAfterTime,
        boolean disqualificationScores,
        boolean oneHandWarnings,
        boolean submissions,
        boolean tiebreaks) {

    /** A scoring button: what the referee saw and the points it gives. */
    public record Action(
            @Min(1) @Max(20) int value,
            @NotBlank @Size(max = 60) String label) {}

    /** Liga Yoseikan, cap. 3.1, and Raul's rules of the F1 (2026-11-13). */
    public static final ScoringRules TAMBO =
            new ScoringRules(List.of(new Action(1, "Punto")), 2, 0, 0, true, true, true, false, false);

    /** FELODA national rules, November 2025 (docs/reglamentos/grappling-feloda-2025.md, art. 38). */
    public static final ScoringRules GRAPPLING = new ScoringRules(
            List.of(
                    new Action(1, "Salida o ataque"),
                    new Action(2, "Derribo, inversión o derribo rápido"),
                    new Action(3, "Montada lateral o derribo de amplitud"),
                    new Action(4, "Montada o espalda")),
            1,
            4,
            15,
            false,
            false,
            false,
            true,
            true);

    public ScoringRules {
        actions = List.copyOf(actions);
    }

    /** The most one action is worth. */
    public int maxPointValue() {
        return actions.stream().mapToInt(Action::value).max().orElse(1);
    }
}
