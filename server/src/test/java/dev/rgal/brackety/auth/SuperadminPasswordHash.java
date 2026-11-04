package dev.rgal.brackety.auth;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;

// Prints the SUPERADMIN_PASSWORD_HASH for a password, with the same Argon2id encoder as the API.
// Run config "server · superadmin password hash" (docs/09-despliegue.md). Reads the password from the console,
// so it never lands in the shell history. Lives in test sources: not in the production jar.
public class SuperadminPasswordHash {

    static final int MIN_LENGTH = 10;

    public static void main(String[] args) throws IOException {
        var password = readPassword();
        if (password == null || password.length() < MIN_LENGTH) {
            System.err.println("At least " + MIN_LENGTH + " characters, please.");
            System.exit(1);
        }
        System.out.println();
        System.out.println("SUPERADMIN_PASSWORD_HASH='" + hash(password) + "'");
    }

    // Hidden in a terminal; the IDE console has none, so there it is a plain line.
    private static String readPassword() throws IOException {
        var console = System.console();
        if (console != null) {
            var chars = console.readPassword("Superadmin password: ");
            return chars == null ? null : new String(chars);
        }
        System.out.print("Superadmin password: ");
        System.out.flush();
        return new BufferedReader(new InputStreamReader(System.in, StandardCharsets.UTF_8)).readLine();
    }

    static String hash(String password) {
        return new SecurityConfig().passwordEncoder().encode(password);
    }
}
