package dev.rgal.brackety.auth.account;

import java.util.Locale;
import java.util.regex.Pattern;

/** Spanish CIF (tax id of an organization): format and control character. */
public final class Cif {

    private static final Pattern FORMAT = Pattern.compile("[ABCDEFGHJNPQRSUVW]\\d{7}[0-9A-J]");
    private static final String CONTROL_LETTERS = "JABCDEFGHI";
    private static final String LETTER_CONTROL = "PQRSNW";
    private static final String DIGIT_CONTROL = "ABEH";

    private Cif() {}

    /** Uppercase, without the spaces, hyphens and dots people type in it. */
    public static String normalize(String cif) {
        return cif == null ? null : cif.replaceAll("[\\s.-]", "").toUpperCase(Locale.ROOT);
    }

    /** {@code cif} already normalized. */
    public static boolean isValid(String cif) {
        if (cif == null || !FORMAT.matcher(cif).matches()) {
            return false;
        }
        var controlDigit = controlDigit(cif.substring(1, 8));
        var type = cif.charAt(0);
        var control = cif.charAt(8);
        var asLetter = control == CONTROL_LETTERS.charAt(controlDigit);
        var asDigit = control == (char) ('0' + controlDigit);
        if (LETTER_CONTROL.indexOf(type) >= 0) {
            return asLetter;
        }
        if (DIGIT_CONTROL.indexOf(type) >= 0) {
            return asDigit;
        }
        return asLetter || asDigit;
    }

    // Positions 1, 3, 5, 7 are doubled and their digits added; positions 2, 4, 6 are added as they are.
    private static int controlDigit(String digits) {
        var sum = 0;
        for (int i = 0; i < digits.length(); i++) {
            var digit = digits.charAt(i) - '0';
            if (i % 2 == 0) {
                var doubled = digit * 2;
                sum += doubled / 10 + doubled % 10;
            } else {
                sum += digit;
            }
        }
        return (10 - sum % 10) % 10;
    }
}
