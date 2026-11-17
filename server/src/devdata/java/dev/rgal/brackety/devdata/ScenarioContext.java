package dev.rgal.brackety.devdata;

import java.time.Clock;
import java.time.LocalDate;
import java.time.ZonedDateTime;

public record ScenarioContext(Clock clock) {

    public LocalDate today() {
        return LocalDate.now(clock);
    }

    public ZonedDateTime now() {
        return ZonedDateTime.now(clock);
    }

    public LocalDate daysFromToday(int days) {
        return today().plusDays(days);
    }
}
