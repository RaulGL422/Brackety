package dev.rgal.brackety.local;

import static org.assertj.core.api.Assertions.assertThatCode;

import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

class EmbeddedPostgresConfigTest {

    @TempDir
    Path dataDir;

    @ParameterizedTest
    @ValueSource(strings = {"", "not-a-pid\n", "  \n5432\n"})
    void ignoresAnEmptyOrCorruptPidFile(String content) throws Exception {
        Files.writeString(dataDir.resolve("postmaster.pid"), content);

        assertThatCode(() -> EmbeddedPostgresConfig.killLeftoverPostgres(dataDir))
                .doesNotThrowAnyException();
    }

    @Test
    void doesNothingWithoutAPidFile() {
        assertThatCode(() -> EmbeddedPostgresConfig.killLeftoverPostgres(dataDir))
                .doesNotThrowAnyException();
    }
}
