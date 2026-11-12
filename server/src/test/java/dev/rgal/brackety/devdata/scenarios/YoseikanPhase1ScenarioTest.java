package dev.rgal.brackety.devdata.scenarios;

import static org.assertj.core.api.Assertions.assertThat;

import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.demo.DemoSetup;
import dev.rgal.brackety.devdata.ScenarioContext;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventOrganizationRepository;
import dev.rgal.brackety.participant.ParticipantRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

class YoseikanPhase1ScenarioTest extends AuthIntegrationTest {

    @Autowired
    DemoSetup demo;

    @Autowired
    ParticipantRepository participants;

    @Autowired
    EventOrganizationRepository organizations;

    @Autowired
    EventCategoryRepository categories;

    @Test
    void seedsTheDemoEventWithParticipantsInEveryChildCategory() {
        new YoseikanPhase1Scenario(demo, participants, organizations, categories).seed(new ScenarioContext(clock));

        assertThat(count("participant"))
                .isEqualTo(YoseikanPhase1Scenario.PARTICIPANTS + YoseikanPhase1Scenario.TEENS + 2);
        var categoriesInUse = jdbc.sql("""
                        select count(distinct c.id) from participant p
                        join event e on e.id = p.event_id
                        join event_category c on c.event_id = e.id
                         and extract(year from age(e.event_date, p.birth_date)) between c.min_age and c.max_age""").query(Integer.class).single();
        assertThat(categoriesInUse).isGreaterThanOrEqualTo(7);
        assertThat(count("event_organization")).isEqualTo(4);
        assertThat(jdbc.sql("select count(*) from participant where organization_id is null")
                        .query(Integer.class)
                        .single())
                .isPositive();
        assertThat(jdbc.sql("select count(*) from participant where height_cm is null")
                        .query(Integer.class)
                        .single())
                .isPositive();
        assertThat(jdbc.sql("select count(*) from participant where category_id is not null")
                        .query(Integer.class)
                        .single())
                .isEqualTo(1);
    }
}
