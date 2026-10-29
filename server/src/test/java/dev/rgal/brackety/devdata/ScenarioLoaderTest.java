package dev.rgal.brackety.devdata;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.transaction.support.TransactionOperations;

class ScenarioLoaderTest {

    private final Clock clock = Clock.fixed(Instant.parse("2026-10-28T10:00:00Z"), ZoneId.of("Europe/Madrid"));
    private final RecordingScenario alpha = new RecordingScenario("alpha");
    private final RecordingScenario beta = new RecordingScenario("beta");

    @Test
    void seedsOnlyTheSelectedScenarioWithTheInjectedClock() {
        loader("beta").run(null);

        assertThat(alpha.seededOn).isEmpty();
        assertThat(beta.seededOn).containsExactly(LocalDate.of(2026, 10, 28));
    }

    @Test
    void unknownScenarioFailsListingTheAvailableOnes() {
        assertThatThrownBy(() -> loader("missing").run(null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("missing")
                .hasMessageContaining("alpha - alpha data")
                .hasMessageContaining("beta - beta data");
    }

    private ScenarioLoader loader(String selected) {
        return new ScenarioLoader(List.of(beta, alpha), clock, TransactionOperations.withoutTransaction(), selected);
    }

    private static final class RecordingScenario implements Scenario {

        private final String name;
        private final List<LocalDate> seededOn = new ArrayList<>();

        RecordingScenario(String name) {
            this.name = name;
        }

        @Override
        public String name() {
            return name;
        }

        @Override
        public String description() {
            return name + " data";
        }

        @Override
        public void seed(ScenarioContext ctx) {
            seededOn.add(ctx.today());
        }
    }
}
