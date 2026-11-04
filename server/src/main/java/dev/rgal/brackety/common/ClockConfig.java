package dev.rgal.brackety.common;

import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

// Every date in the app comes from this clock, so tests and local scenarios can move "today".
@Configuration(proxyBeanMethods = false)
class ClockConfig {

    @Bean
    Clock clock(@Value("${brackety.time-zone}") ZoneId zone) {
        return Clock.system(zone);
    }
}
