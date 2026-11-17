package dev.rgal.brackety.event;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** A mat out of use (F1-1): it keeps when and with whom, and a referee from the settings puts it back in use. */
class MatTest {

    private final UUID referee = UUID.randomUUID();
    private final Instant at = Instant.parse("2027-01-24T10:00:00Z");

    @Test
    void disablingKeepsItsRefereeForLaterAndEnablingGivesItBack() {
        var mat = new Mat(UUID.randomUUID(), 1, referee);

        mat.disable(at);
        assertThat(mat.isDisabled()).isTrue();
        assertThat(mat.getRefereeAccountId()).isNull();
        assertThat(mat.getDisabledAt()).isEqualTo(at);
        assertThat(mat.getDisabledRefereeAccountId()).isEqualTo(referee);

        mat.enable();
        assertThat(mat.isDisabled()).isFalse();
        assertThat(mat.getRefereeAccountId()).isEqualTo(referee);
        assertThat(mat.getDisabledRefereeAccountId()).isNull();
    }

    @Test
    void aRefereeFromTheSettingsPutsItBackInUseButNoRefereeLeavesItOut() {
        var mat = new Mat(UUID.randomUUID(), 1, referee);
        mat.disable(at);

        mat.assignReferee(null);
        assertThat(mat.isDisabled()).isTrue();

        var other = UUID.randomUUID();
        mat.assignReferee(other);
        assertThat(mat.isDisabled()).isFalse();
        assertThat(mat.getRefereeAccountId()).isEqualTo(other);
        assertThat(mat.getDisabledRefereeAccountId()).isNull();
    }
}
