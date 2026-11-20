package dev.rgal.brackety.common;

import java.text.Collator;
import java.util.Comparator;
import java.util.Locale;

/**
 * Alphabetical order of people's and clubs' names as a Spanish reader expects it: Álvaro next to Alba, Óscar before
 * Pablo, case aside. Sorted here and not in SQL, where the order depends on the database's locale (on the Linux
 * servers an accented name went to the end).
 */
public final class Names {

    /** Thread-safe: {@link Collator#compare} is synchronized. */
    public static final Comparator<String> ORDER = Comparator.nullsLast(spanish()::compare);

    private Names() {}

    private static Collator spanish() {
        var collator = Collator.getInstance(Locale.of("es", "ES"));
        // Accents count only between names otherwise equal (Alvaro before Álvaro); case never does.
        collator.setStrength(Collator.SECONDARY);
        return collator;
    }
}
