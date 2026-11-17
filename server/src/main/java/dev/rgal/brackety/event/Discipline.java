package dev.rgal.brackety.event;

import java.util.List;

/**
 * What a phase competes in; each one will have its own scoring template. Only tambo has a scoreboard today. Each
 * sport says whether it asks for weight and height and which warning reasons the referee picks from; an event may say
 * otherwise.
 */
public enum Discipline {
    // What the rulebook forbids in tambo (docs/reglamentos/yoseikan-2027.md, cap. 3.1).
    TAMBO(
            true,
            MeasureRequirement.OPTIONAL,
            MeasureRequirement.OPTIONAL,
            List.of(
                    "Proyección o golpeo",
                    "Tirarse rodando",
                    "Ataque de pique",
                    "Exceso de potencia",
                    "Conducta antideportiva")),
    GROUND(false, MeasureRequirement.OPTIONAL, MeasureRequirement.OPTIONAL, List.of()),
    THROWS(false, MeasureRequirement.OPTIONAL, MeasureRequirement.OPTIONAL, List.of()),
    TECHNICAL_EXPRESSION(false, MeasureRequirement.OPTIONAL, MeasureRequirement.OPTIONAL, List.of());

    private final boolean available;
    private final MeasureRequirement weight;
    private final MeasureRequirement height;
    private final List<String> warningReasons;

    Discipline(boolean available, MeasureRequirement weight, MeasureRequirement height, List<String> warningReasons) {
        this.available = available;
        this.weight = weight;
        this.height = height;
        this.warningReasons = warningReasons;
    }

    public boolean isAvailable() {
        return available;
    }

    public MeasureRequirement weight() {
        return weight;
    }

    public MeasureRequirement height() {
        return height;
    }

    public List<String> warningReasons() {
        return warningReasons;
    }
}
