package dev.rgal.brackety.common;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.Test;

class NamesTest {

    @Test
    void accentedNamesGoWithTheirLetterNotAtTheEnd() {
        assertThat(sorted("Zoe", "Óscar", "Pablo", "Álvaro", "Emma", "Alba", "Íñigo", "Hugo"))
                .containsExactly("Alba", "Álvaro", "Emma", "Hugo", "Íñigo", "Óscar", "Pablo", "Zoe");
    }

    @Test
    void ñIsItsOwnLetterBetweenNAndO() {
        assertThat(sorted("Óscar", "Ñuño", "Nuria", "Noa")).containsExactly("Noa", "Nuria", "Ñuño", "Óscar");
    }

    @Test
    void caseNeverCountsAndTheAccentOnlyBreaksATie() {
        assertThat(Names.ORDER.compare("lucía", "Lucía")).isZero();
        assertThat(sorted("Álvaro", "alvaro")).containsExactly("alvaro", "Álvaro");
    }

    @Test
    void namesMissingGoLast() {
        assertThat(sorted(null, "Alba")).containsExactly("Alba", null);
    }

    private static List<String> sorted(String... names) {
        var list = new ArrayList<>(Arrays.asList(names));
        list.sort(Names.ORDER);
        return list;
    }
}
