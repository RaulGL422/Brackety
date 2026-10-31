package dev.rgal.brackety.local;

import dev.rgal.brackety.devdata.DevScenario;
import dev.rgal.brackety.devdata.ScenarioLoader;
import java.time.Clock;
import java.time.Duration;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;

// Scenarios are not @Component on purpose: the main app scan would load them into every test context.
@TestConfiguration(proxyBeanMethods = false)
@Import({EmbeddedPostgresConfig.class, LocalGoogleConfig.class, LocalAdminConfig.class, ScenarioLoader.class})
@ComponentScan(
        basePackages = "dev.rgal.brackety.devdata",
        useDefaultFilters = false,
        includeFilters = @ComponentScan.Filter(DevScenario.class))
class LocalConfig {

    @Bean
    @Primary
    Clock localClock(@Qualifier("clock") Clock clock, @Value("${brackety.clock.today:}") String today) {
        return today.isBlank() ? clock : shiftedTo(clock, LocalDate.parse(today));
    }

    static Clock shiftedTo(Clock clock, LocalDate today) {
        var days = ChronoUnit.DAYS.between(LocalDate.now(clock), today);
        return Clock.offset(clock, Duration.ofDays(days));
    }
}
