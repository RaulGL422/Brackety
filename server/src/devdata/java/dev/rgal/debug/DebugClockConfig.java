package dev.rgal.debug;

import java.time.Clock;
import java.time.LocalDate;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;

/** The debug server's clock, the one every date in the app reads; it starts on {@code brackety.clock.today}. */
public class DebugClockConfig {

    @Bean
    @Primary
    DebugClock debugClock(@Qualifier("clock") Clock clock, @Value("${brackety.clock.today:}") String today) {
        var debug = new DebugClock(clock);
        debug.moveTo(today.isBlank() ? null : LocalDate.parse(today));
        return debug;
    }
}
