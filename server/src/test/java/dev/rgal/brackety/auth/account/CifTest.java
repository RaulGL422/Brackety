package dev.rgal.brackety.auth.account;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class CifTest {

    @Test
    void acceptsAValidControlAsTheTypeAllows() {
        assertThat(Cif.isValid("B12345674")).isTrue();
        assertThat(Cif.isValid("G12345674")).isTrue();
        assertThat(Cif.isValid("G1234567D")).isTrue();
        assertThat(Cif.isValid("P1234567D")).isTrue();
        assertThat(Cif.isValid("A12345674")).isTrue();
        // Doubled 9 → 18 → 1 + 8; sum 39, control 1 (A).
        assertThat(Cif.isValid("Q9999999A")).isFalse();
    }

    @Test
    void lettersPQRSNWNeedTheControlLetterAndABEHTheControlDigit() {
        for (var type : "PQRSNW".toCharArray()) {
            assertThat(Cif.isValid(type + "1234567D")).as("%s letter", type).isTrue();
            assertThat(Cif.isValid(type + "12345674")).as("%s digit", type).isFalse();
        }
        for (var type : "ABEH".toCharArray()) {
            assertThat(Cif.isValid(type + "12345674")).as("%s digit", type).isTrue();
            assertThat(Cif.isValid(type + "1234567D")).as("%s letter", type).isFalse();
        }
        for (var type : "CDFGJUV".toCharArray()) {
            assertThat(Cif.isValid(type + "12345674")).as("%s digit", type).isTrue();
            assertThat(Cif.isValid(type + "1234567D")).as("%s letter", type).isTrue();
        }
    }

    @Test
    void rejectsAWrongControlLengthOrFirstLetter() {
        assertThat(Cif.isValid("B12345675")).isFalse();
        assertThat(Cif.isValid("G1234567E")).isFalse();
        assertThat(Cif.isValid("B1234567")).isFalse();
        assertThat(Cif.isValid("B123456744")).isFalse();
        assertThat(Cif.isValid("I12345674")).isFalse();
        assertThat(Cif.isValid("K12345674")).isFalse();
        assertThat(Cif.isValid("12345678Z")).isFalse();
        assertThat(Cif.isValid("")).isFalse();
        assertThat(Cif.isValid(null)).isFalse();
    }

    @Test
    void normalizesCaseSpacesHyphensAndDots() {
        assertThat(Cif.normalize(" g-1234.567 4 ")).isEqualTo("G12345674");
        assertThat(Cif.isValid(Cif.normalize("b-12.345.674"))).isTrue();
    }
}
