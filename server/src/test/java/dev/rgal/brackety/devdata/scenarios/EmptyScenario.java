package dev.rgal.brackety.devdata.scenarios;

import dev.rgal.brackety.devdata.DevScenario;
import dev.rgal.brackety.devdata.Scenario;
import dev.rgal.brackety.devdata.ScenarioContext;

@DevScenario
class EmptyScenario implements Scenario {

    @Override
    public String name() {
        return "empty";
    }

    @Override
    public String description() {
        return "Empty database, migrations only";
    }

    @Override
    public void seed(ScenarioContext ctx) {}
}
