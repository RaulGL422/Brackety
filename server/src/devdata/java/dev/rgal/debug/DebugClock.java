package dev.rgal.debug;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;

/**
 * The app's clock in the debug environment: the superadmin moves it to another day and the hours keep running
 * (docs/modulos/entornos.md). Every date in the app comes from the {@code Clock} bean, so this moves all of them.
 */
public final class DebugClock extends Clock {

    private final Clock real;
    private volatile Duration offset = Duration.ZERO;

    public DebugClock(Clock real) {
        this.real = real;
    }

    /** Null goes back to the real day. */
    public void moveTo(LocalDate day) {
        offset = day == null ? Duration.ZERO : Duration.ofDays(ChronoUnit.DAYS.between(LocalDate.now(real), day));
    }

    public boolean isSimulated() {
        return !offset.isZero();
    }

    @Override
    public ZoneId getZone() {
        return real.getZone();
    }

    @Override
    public Clock withZone(ZoneId zone) {
        return Clock.offset(real.withZone(zone), offset);
    }

    @Override
    public Instant instant() {
        return real.instant().plus(offset);
    }
}
