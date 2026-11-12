package dev.rgal.brackety;

import dev.rgal.brackety.auth.SecurityConfig;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class BracketyApplication {

    /** The flag that prints the hash of the password read from stdin, without starting the server. */
    static final String SUPERADMIN_HASH = "--superadmin-hash";

    public static void main(String[] args) throws IOException {
        // The hall laptop's start-event.ps1 hashes its superadmin password with the same encoder.
        if (args.length == 1 && args[0].equals(SUPERADMIN_HASH)) {
            var line = new BufferedReader(new InputStreamReader(System.in, StandardCharsets.UTF_8)).readLine();
            // A console set to UTF-8 makes Windows PowerShell put a byte order mark before the piped text: hashed
            // with it, the password written to superadmin.txt would never match.
            var password = line == null ? null : line.replace("\uFEFF", "");
            if (password == null || password.isBlank()) {
                System.err.println("No password on stdin.");
                System.exit(1);
            }
            System.out.println(SecurityConfig.argon2().encode(password.strip()));
            return;
        }
        SpringApplication.run(BracketyApplication.class, args);
    }
}
