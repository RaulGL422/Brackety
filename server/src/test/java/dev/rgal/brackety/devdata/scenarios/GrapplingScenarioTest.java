package dev.rgal.brackety.devdata.scenarios;

import static org.assertj.core.api.Assertions.assertThat;

import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.auth.account.VerifiedAccounts;
import dev.rgal.brackety.devdata.ScenarioContext;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventOrganizationRepository;
import dev.rgal.brackety.event.EventStaffRepository;
import dev.rgal.brackety.event.MatRepository;
import dev.rgal.brackety.event.OrganizationRepository;
import dev.rgal.brackety.league.NewEventService;
import dev.rgal.brackety.participant.ParticipantRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

class GrapplingScenarioTest extends AuthIntegrationTest {

    @Autowired
    VerifiedAccounts accounts;

    @Autowired
    NewEventService newEvents;

    @Autowired
    EventStaffRepository staff;

    @Autowired
    MatRepository mats;

    @Autowired
    EventCategoryRepository categories;

    @Autowired
    OrganizationRepository clubs;

    @Autowired
    EventOrganizationRepository eventClubs;

    @Autowired
    ParticipantRepository participants;

    @Test
    void seedsAGrapplingEventWithEveryoneInTheirCategory() {
        new GrapplingScenario(accounts, newEvents, staff, mats, categories, clubs, eventClubs, participants)
                .seed(new ScenarioContext(clock));

        assertThat(jdbc.sql("select t.code from event e join sport_template_version v on v.id = e.sport_version_id"
                                + " join sport_template t on t.id = v.template_id")
                        .query(String.class)
                        .single())
                .isEqualTo("GRAPPLING");
        assertThat(jdbc.sql("select count(*) from event_category where match_seconds is not null")
                        .query(Integer.class)
                        .single())
                .isEqualTo(GrapplingScenario.CATEGORIES.size());
        assertThat(count("participant"))
                .isEqualTo(GrapplingScenario.CATEGORIES.stream()
                        .mapToInt(GrapplingScenario.Band::size)
                        .sum());
        // Gi and no-gi of an age overlap: nobody is left to be placed by age.
        assertThat(jdbc.sql("select count(*) from participant where category_id is null")
                        .query(Integer.class)
                        .single())
                .isZero();
        assertThat(jdbc.sql("select count(*) from mat where referee_account_id is not null")
                        .query(Integer.class)
                        .single())
                .isEqualTo(GrapplingScenario.MATS);
        assertThat(jdbc.sql("select count(*) from participant where organization_id is null")
                        .query(Integer.class)
                        .single())
                .isPositive();
    }
}
