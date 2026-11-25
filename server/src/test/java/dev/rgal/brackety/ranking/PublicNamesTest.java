package dev.rgal.brackety.ranking;

import static org.assertj.core.api.Assertions.assertThat;

import dev.rgal.brackety.participant.Participant;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;

class PublicNamesTest {

    private final PublicNames names = new PublicNames(List.of(person("Ana", "García"), person("Ana", "García López")));

    @Test
    void aLastNameColumnKeepsItsInitial() {
        assertThat(names.apply("lastName", "Álvarez Ruiz")).isEqualTo("Á.");
        assertThat(names.apply("lastName", " ")).isEqualTo("");
    }

    // Red, blue, winner, how it ended and the team members name people among other words.
    @Test
    void aNameInsideACellIsShortenedTheLongestFirst() {
        assertThat(names.apply("endReason", "Descalificación de Ana García López"))
                .isEqualTo("Descalificación de Ana G.");
        assertThat(names.apply("teamMembers", "Ana García, Ana García López")).isEqualTo("Ana G., Ana G.");
        assertThat(names.apply("club", "Club Norte")).isEqualTo("Club Norte");
        assertThat(names.apply("total", 12)).isEqualTo(12);
    }

    private static Participant person(String first, String last) {
        var p = new Participant(java.util.UUID.randomUUID(), Instant.EPOCH);
        p.update(first, last, LocalDate.of(2015, 1, 1), 120, true);
        return p;
    }
}
