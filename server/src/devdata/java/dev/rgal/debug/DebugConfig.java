package dev.rgal.debug;

import dev.rgal.brackety.auth.admin.AdminAuditLog;
import dev.rgal.brackety.devdata.DevScenario;
import dev.rgal.brackety.devdata.Scenario;
import java.util.List;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.transaction.support.TransactionOperations;

/**
 * The debug server on top of the app (docs/modulos/entornos.md). Outside {@code dev.rgal.brackety} and without
 * {@code @Configuration} on purpose: neither the app's scan nor the tests' pick it up; only
 * {@link DebugBracketyApplication} and the tests that ask for it. The clock is apart ({@link DebugClockConfig}):
 * the tests bring their own.
 */
@Import(DebugController.class)
@ComponentScan(
        basePackages = "dev.rgal.brackety.devdata",
        useDefaultFilters = false,
        includeFilters = @ComponentScan.Filter(DevScenario.class))
public class DebugConfig {

    @Bean
    DebugData debugData(
            List<Scenario> scenarios,
            DebugClock clock,
            JdbcClient jdbc,
            TransactionOperations transactions,
            AdminAuditLog audit) {
        return new DebugData(scenarios, clock, jdbc, transactions, audit);
    }
}
