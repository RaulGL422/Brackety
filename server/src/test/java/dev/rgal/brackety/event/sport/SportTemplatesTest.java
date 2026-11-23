package dev.rgal.brackety.event.sport;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;

import dev.rgal.brackety.event.EventApiTest;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.event.EventRepository;
import dev.rgal.brackety.event.MeasureRequirement;
import dev.rgal.brackety.event.Modality.FormatRules;
import dev.rgal.brackety.event.TestSports;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

/**
 * Sports are data (docs/producto/plantillas-deporte.md, step 1): the seeded templates give exactly the rules the code
 * had, and the list to choose from comes from them.
 */
class SportTemplatesTest extends EventApiTest {

    @Autowired
    SportCatalog sports;

    @Autowired
    EventRepository events;

    @Test
    void tamboStartsWithTheRulesItAlwaysHad() {
        var tambo = sports.latest("TAMBO").rules();

        assertThat(tambo.scoring()).isEqualTo(TestSports.TAMBO);
        assertThat(tambo.warningReasons()).isEqualTo(TestSports.TAMBO_WARNINGS);
        assertThat(tambo.weight()).isEqualTo(MeasureRequirement.OPTIONAL);
        assertThat(tambo.height()).isEqualTo(MeasureRequirement.OPTIONAL);
        var modality = tambo.modality();
        assertThat(modality.individual()).isEqualTo(new FormatRules(60, 15));
        assertThat(modality.team()).isEqualTo(new FormatRules(180, 0));
        assertThat(modality.getMinRestSeconds()).isEqualTo(30);
        assertThat(modality.getChangeoverSeconds()).isEqualTo(30);
    }

    @Test
    void grapplingStartsWithTheRulesItAlwaysHad() {
        var grappling = sports.latest("GRAPPLING").rules();

        assertThat(grappling.scoring()).isEqualTo(TestSports.GRAPPLING);
        assertThat(grappling.warningReasons()).isEqualTo(TestSports.GRAPPLING_WARNINGS);
        assertThat(grappling.weight()).isEqualTo(MeasureRequirement.OPTIONAL);
        assertThat(grappling.height()).isEqualTo(MeasureRequirement.OFF);
        var modality = grappling.modality();
        assertThat(modality.individual()).isEqualTo(new FormatRules(300, 0));
        assertThat(modality.team()).isEqualTo(new FormatRules(300, 0));
        assertThat(modality.getMinRestSeconds()).isEqualTo(30);
        assertThat(modality.getChangeoverSeconds()).isEqualTo(30);
    }

    @Test
    void theListComesFromTheTemplatesInOrderWithTheirNames() throws Exception {
        assertThat(sports.latest().stream().map(SportVersion::code))
                .containsExactly("TAMBO", "GRAPPLING", "GROUND", "THROWS", "TECHNICAL_EXPRESSION");

        call(get("/api/v1/events/disciplines"), "club1")
                .andExpect(jsonPath("$", hasSize(5)))
                .andExpect(jsonPath("$[0].discipline").value("TAMBO"))
                .andExpect(jsonPath("$[0].available").value(true))
                .andExpect(jsonPath("$[2].names.es").value("Suelo"))
                .andExpect(jsonPath("$[2].names.en").value("Ground"))
                .andExpect(jsonPath("$[2].available").value(false));
    }

    @Test
    void anUnknownSportOrOneWithoutScoreboardIsNotPlayed() {
        assertThatThrownBy(() -> sports.playable("CURLING")).isInstanceOf(EventException.class);
        assertThatThrownBy(() -> sports.playable("GROUND")).isInstanceOf(EventException.class);
    }

    @Test
    void anEventKeepsTheVersionOfItsSport() {
        var event = events.findById(eventId).orElseThrow();

        assertThat(event.getSport().code()).isEqualTo("TAMBO");
        assertThat(event.getSport().getVersion()).isEqualTo(1);
    }
}
