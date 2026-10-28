package dev.rgal.brackety.local;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import org.junit.jupiter.api.Test;

class LocalConfigTest {

    private final Clock base = Clock.fixed(Instant.parse("2026-10-28T08:30:00Z"), ZoneId.of("Europe/Madrid"));

    @Test
    void shiftsTheDateAndKeepsTheTimeOfDay() {
        var shifted = LocalConfig.shiftedTo(base, LocalDate.of(2027, 3, 10));

        assertThat(LocalDate.now(shifted)).isEqualTo(LocalDate.of(2027, 3, 10));
        assertThat(LocalTime.now(shifted)).isEqualTo(LocalTime.now(base));
    }

    @Test
    void canGoBackInTime() {
        var shifted = LocalConfig.shiftedTo(base, LocalDate.of(2026, 1, 1));

        assertThat(LocalDate.now(shifted)).isEqualTo(LocalDate.of(2026, 1, 1));
    }
}
