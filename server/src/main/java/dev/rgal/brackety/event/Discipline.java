package dev.rgal.brackety.event;

/** What a phase competes in; each one will have its own scoring template. Only tambo has a scoreboard today. */
public enum Discipline {
    TAMBO(true),
    GROUND(false),
    THROWS(false),
    TECHNICAL_EXPRESSION(false);

    private final boolean available;

    Discipline(boolean available) {
        this.available = available;
    }

    public boolean isAvailable() {
        return available;
    }
}
