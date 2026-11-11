package dev.rgal.brackety.ranking;

import dev.rgal.brackety.grouping.Competitor;
import dev.rgal.brackety.grouping.Match;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

/** How the exported sheets write values: Spanish words, dd/mm/aaaa dates, mm:ss durations. */
final class SheetText {

    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter TIME = DateTimeFormatter.ofPattern("HH:mm:ss");

    private SheetText() {}

    static String date(LocalDate date) {
        return date == null ? null : DATE.format(date);
    }

    static String date(Instant instant, ZoneId zone) {
        return instant == null ? null : DATE.format(instant.atZone(zone));
    }

    static String time(Instant instant, ZoneId zone) {
        return instant == null ? null : TIME.format(instant.atZone(zone));
    }

    /** "m:ss", e.g. 1:05. */
    static String duration(long millis) {
        var d = Duration.ofMillis(millis);
        return "%d:%02d".formatted(d.toMinutes(), d.toSecondsPart());
    }

    static String yesNo(boolean value) {
        return value ? "sí" : "no";
    }

    static String side(String side) {
        if (side == null) {
            return null;
        }
        return switch (side) {
            case "RED" -> "Rojo";
            case "BLUE" -> "Azul";
            default -> side;
        };
    }

    /** A clock adjustment in words, not a sign: a cell starting with + or - is neutralised for spreadsheets. */
    static String clockAdjust(long deltaMs) {
        return (deltaMs > 0 ? "añade " : "quita ") + Math.abs(deltaMs) / 1000 + " s";
    }

    /** Unknown types (added later to the scoreboard) keep their code. */
    static String action(String type) {
        return switch (type) {
            case "START" -> "Iniciar reloj";
            case "STOP" -> "Parar reloj";
            case "POINT" -> "Punto";
            case "POINT_REMOVED" -> "Quitar punto";
            case "WARNING" -> "Advertencia";
            case "ONE_HAND_WARNING" -> "Advertencia por golpear con una mano";
            case "DISQUALIFICATION" -> "Descalificación";
            case "CLOCK_ADJUST" -> "Ajuste del reloj";
            case "UNDO" -> "Deshacer";
            case "FINISH" -> "Finalizar combate";
            default -> type;
        };
    }

    static String status(Match.Status status) {
        return switch (status) {
            case PENDING -> "Pendiente";
            case IN_PROGRESS -> "En curso";
            case FINISHED -> "Terminado";
        };
    }

    static String medal(Integer medal) {
        if (medal == null) {
            return null;
        }
        return switch (medal) {
            case 1 -> "Oro (1.º)";
            case 2 -> "Plata (2.º)";
            default -> "Bronce (3.º)";
        };
    }

    /** "Equipo N (names)" for a team, so the sheet says who fought. */
    static String label(Competitor c) {
        return c.isTeam() ? c.name() + " (" + String.join(", ", c.memberNames()) + ")" : c.name();
    }
}
