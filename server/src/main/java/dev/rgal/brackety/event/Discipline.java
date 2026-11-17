package dev.rgal.brackety.event;

/**
 * What a phase competes in; each one will have its own scoring template. Only tambo has a scoreboard today. Each
 * sport says whether it asks for weight and height; an event may say otherwise.
 */
public enum Discipline {
    TAMBO(true, MeasureRequirement.OPTIONAL, MeasureRequirement.OPTIONAL),
    GROUND(false, MeasureRequirement.OPTIONAL, MeasureRequirement.OPTIONAL),
    THROWS(false, MeasureRequirement.OPTIONAL, MeasureRequirement.OPTIONAL),
    TECHNICAL_EXPRESSION(false, MeasureRequirement.OPTIONAL, MeasureRequirement.OPTIONAL);

    private final boolean available;
    private final MeasureRequirement weight;
    private final MeasureRequirement height;

    Discipline(boolean available, MeasureRequirement weight, MeasureRequirement height) {
        this.available = available;
        this.weight = weight;
        this.height = height;
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
}
