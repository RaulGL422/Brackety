package dev.rgal.brackety.devdata;

import java.time.Clock;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.transaction.support.TransactionOperations;

public class ScenarioLoader implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(ScenarioLoader.class);

    private final List<Scenario> scenarios;
    private final Clock clock;
    private final TransactionOperations transactions;
    private final String selected;

    public ScenarioLoader(
            List<Scenario> scenarios,
            Clock clock,
            TransactionOperations transactions,
            @Value("${brackety.scenario:empty}") String selected) {
        this.scenarios =
                scenarios.stream().sorted(Comparator.comparing(Scenario::name)).toList();
        this.clock = clock;
        this.transactions = transactions;
        this.selected = selected;
    }

    @Override
    public void run(ApplicationArguments args) {
        var scenario = find(selected);
        var ctx = new ScenarioContext(clock);
        transactions.executeWithoutResult(status -> scenario.seed(ctx));
        log.info("Scenario '{}' loaded, today is {}. Available:\n{}", scenario.name(), ctx.today(), catalog());
    }

    Scenario find(String name) {
        return scenarios.stream()
                .filter(s -> s.name().equals(name))
                .findFirst()
                .orElseThrow(() ->
                        new IllegalArgumentException("Unknown scenario '" + name + "'. Available:\n" + catalog()));
    }

    private String catalog() {
        return scenarios.stream()
                .map(s -> "  " + s.name() + " - " + s.description())
                .collect(Collectors.joining("\n"));
    }
}
