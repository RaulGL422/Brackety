package dev.rgal.brackety.event;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

/**
 * How a sport scores a match, as data: each modality keeps its own copy, so an event never changes when a sport's
 * defaults do. The sport templates (docs/producto/plantillas-deporte.md) will be stored sets of these; for now the
 * built-in ones are {@link #TAMBO} and {@link #GRAPPLING}.
 *
 * @param actions the scoring buttons of the referee, each with its points
 * @param warningPoints what the rival gets for each warning of a fighter, in order, starting over when the list
 *     ends: tambo [0, 1] (every second one), grappling [1] (every one), a ladder like [0, 1, 2] elsewhere
 * @param warningsToDisqualify the warning that disqualifies; 0 = none
 * @param superiorityGap the points difference that ends the match; 0 = none
 * @param pointsAfterTime the last action's point still counts once the clock shows 0:00
 * @param disqualificationScores a disqualification scores 0 for the disqualified and the limit for the rival
 * @param oneHandWarnings the one-hand warning exists (tambo, ages 4 to 8)
 * @param finishes the actions that win the match at once (grappling: a submission), by name; empty: none
 * @param tiebreaks what breaks a tie on points, in order; empty: the tie stands (tambo)
 * @param classification the points each way of winning gives (FELODA, art. 39); empty: ranked by the points scored
 */
public record ScoringRules(
        @NotEmpty @Size(max = 10) List<@Valid Action> actions,
        @NotEmpty @Size(max = 10) List<@NotNull @Min(0) @Max(20) Integer> warningPoints,
        @Min(0) @Max(10) int warningsToDisqualify,
        @Min(0) @Max(100) int superiorityGap,
        boolean pointsAfterTime,
        boolean disqualificationScores,
        boolean oneHandWarnings,
        @Size(max = 5) List<@NotBlank @Size(max = 40) String> finishes,
        @Size(max = 4) List<@NotNull Tiebreak> tiebreaks,
        @Size(max = 10) List<@Valid Classification> classification) {

    /** A scoring button: what the referee saw and the points it gives. */
    public record Action(
            @Min(1) @Max(20) int value,
            @NotBlank @Size(max = 60) String label) {}

    /** A way to break a tie on points, checked in the order the rules list them. */
    public enum Tiebreak {
        /** The action of most value, then how many of it (grappling, art. 31). */
        BEST_ACTION,
        FEWER_WARNINGS,
        /** Whoever scored the last action still in force. */
        LAST_TO_SCORE,
        /** Still tied: an extra time decides, and the referee says who won it (grappling, art. 32). */
        EXTRA_TIME
    }

    /**
     * What a win that ended as {@code end} (a match end reason: SUBMISSION, SUPERIORITY…) gives the winner, the loser,
     * and the loser if they scored.
     */
    public record Classification(
            @NotBlank @Size(max = 20) String end,
            @Min(0) @Max(10) int winner,
            @Min(0) @Max(10) int loser,
            @Min(0) @Max(10) int loserWhoScored) {}

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
            // Art. 39: submission or disqualification 5-0, superiority 4-0 or 4-1, decision 3-0 or 3-1, four
            // warnings 3-0, extra time 2-0.
            List.of(
                    new Classification("SUBMISSION", 5, 0, 0),
                    new Classification("DISQUALIFICATION", 5, 0, 0),
                    new Classification("SUPERIORITY", 4, 0, 1),
                    new Classification("TIME", 3, 0, 1),
                    new Classification("WARNINGS", 3, 0, 0),
                    new Classification("EXTRA_TIME", 2, 0, 0)));

    public ScoringRules {
        actions = List.copyOf(actions);
        warningPoints = List.copyOf(warningPoints);
        finishes = finishes == null ? List.of() : List.copyOf(finishes);
        tiebreaks = tiebreaks == null ? List.of() : List.copyOf(tiebreaks);
        // Rules stored before classification existed are tambo's: ranked by points.
        classification = classification == null ? List.of() : List.copyOf(classification);
    }

    /** Ranked by classification points and wins (grappling) rather than by the points scored (tambo). */
    public boolean ranksByClassification() {
        return !classification.isEmpty();
    }

    /** What the rival gets for a fighter's {@code n}th warning (1: the first). */
    public int warningPoints(int n) {
        return warningPoints.get((n - 1) % warningPoints.size());
    }

    public boolean hasExtraTime() {
        return tiebreaks.contains(Tiebreak.EXTRA_TIME);
    }

    public ScoringRules withSuperiorityGap(int gap) {
        return new ScoringRules(
                actions,
                warningPoints,
                warningsToDisqualify,
                gap,
                pointsAfterTime,
                disqualificationScores,
                oneHandWarnings,
                finishes,
                tiebreaks,
                classification);
    }

    /** The most one action is worth. */
    public int maxPointValue() {
        return actions.stream().mapToInt(Action::value).max().orElse(1);
    }
}
