package dev.rgal.brackety.devdata;

/** A named dataset for manual testing. Dates must come from {@link ScenarioContext}, never be hardcoded. */
public interface Scenario {

    String name();

    String description();

    void seed(ScenarioContext ctx);
}
