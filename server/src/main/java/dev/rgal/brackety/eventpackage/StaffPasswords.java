package dev.rgal.brackety.eventpackage;

import java.security.SecureRandom;

/** Random passwords for the staff accounts a package creates, easy to type on a phone. */
final class StaffPasswords {

    // Lowercase and digits without the look-alikes l, 1, o and 0: 32 symbols, 50 bits in 10 characters.
    static final String ALPHABET = "abcdefghijkmnpqrstuvwxyz23456789";
    static final int LENGTH = 10;

    private static final SecureRandom RANDOM = new SecureRandom();

    private StaffPasswords() {}

    static String next() {
        var password = new StringBuilder(LENGTH);
        for (int i = 0; i < LENGTH; i++) {
            password.append(ALPHABET.charAt(RANDOM.nextInt(ALPHABET.length())));
        }
        return password.toString();
    }
}
