package dev.rgal.brackety.auth;

import java.security.SecureRandom;
import java.util.Base64;

// 256 random bits, URL-safe: refresh tokens and emailed links. Only their Sha256 is stored.
final class RandomTokens {

    private static final SecureRandom RANDOM = new SecureRandom();

    private RandomTokens() {}

    static String newToken() {
        var bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
