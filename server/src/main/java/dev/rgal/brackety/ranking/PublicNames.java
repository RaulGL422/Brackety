package dev.rgal.brackety.ranking;

import dev.rgal.brackety.participant.Participant;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * «Para publicar» (docs/producto/exportaciones.md): each participant as their first name and the initial of their
 * last name, also inside the cells that name them among other words (red, blue, winner, how it ended, team members).
 */
final class PublicNames {

    /** Full name to short one, longest first so "Ana García López" is not cut as "Ana García". */
    private final Map<String, String> names = new LinkedHashMap<>();

    PublicNames(List<Participant> participants) {
        participants.stream()
                .sorted(Comparator.comparingInt((Participant p) -> fullName(p).length())
                        .reversed())
                .forEach(p -> names.putIfAbsent(fullName(p), p.getFirstName() + " " + initial(p.getLastName())));
    }

    /** The cell of {@code column}, with its names shortened. */
    Object apply(String column, Object value) {
        if (!(value instanceof String text)) {
            return value;
        }
        if (column.equals("lastName")) {
            return initial(text);
        }
        for (var name : names.entrySet()) {
            text = text.replace(name.getKey(), name.getValue());
        }
        return text;
    }

    private static String fullName(Participant p) {
        return p.getFirstName() + " " + p.getLastName();
    }

    private static String initial(String lastName) {
        var trimmed = lastName == null ? "" : lastName.strip();
        return trimmed.isEmpty() ? "" : trimmed.substring(0, trimmed.offsetByCodePoints(0, 1)) + ".";
    }
}
