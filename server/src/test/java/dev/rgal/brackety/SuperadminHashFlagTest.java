package dev.rgal.brackety;

import static org.assertj.core.api.Assertions.assertThat;

import dev.rgal.brackety.auth.SecurityConfig;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

/** start-event.ps1 makes the hall superadmin's hash with {@code java -jar brackety.jar --superadmin-hash}. */
class SuperadminHashFlagTest {

    private final InputStream in = System.in;
    private final PrintStream out = System.out;

    @AfterEach
    void restore() {
        System.setIn(in);
        System.setOut(out);
    }

    @Test
    void printsAHashOfThePasswordReadFromStdinWithoutStartingTheServer() throws Exception {
        var printed = new ByteArrayOutputStream();
        System.setIn(new ByteArrayInputStream("hall-password-123\n".getBytes(StandardCharsets.UTF_8)));
        System.setOut(new PrintStream(printed, true, StandardCharsets.UTF_8));

        BracketyApplication.main(new String[] {BracketyApplication.SUPERADMIN_HASH});

        var hash = printed.toString(StandardCharsets.UTF_8).strip();
        assertThat(hash).startsWith("$argon2id$");
        assertThat(SecurityConfig.argon2().matches("hall-password-123", hash)).isTrue();
    }
}
