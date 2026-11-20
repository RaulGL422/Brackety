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
    // FELODA national rules, Nov. 2025 (docs/reglamentos/grappling-feloda-2025.md, art. 41 and 44): each one is a
    // warning and a point for the rival; with gi and without, the age limits named in the reason.
    GRAPPLING(
            true,
            MeasureRequirement.OPTIONAL,
            MeasureRequirement.OFF,
            List.of(
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
                    "Ignorar al árbitro o conducta antideportiva")),
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

    /** The rules a new event of this sport starts with; the club changes what it needs. */
    public Modality defaultModality() {
        return this == GRAPPLING ? Modality.grappling() : Modality.tambo();
    }
}
