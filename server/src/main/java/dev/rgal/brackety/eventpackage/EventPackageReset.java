package dev.rgal.brackety.eventpackage;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Optional;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Back to the package the hall laptop started with (BRACKETY_RESET_PACKAGE): every event and league goes, with all
 * they hold (groups, teams, matches, participants), and the package loads again. Accounts stay, with their passwords;
 * so does the superadmin's audit. All or nothing: if the package does not load, nothing is wiped.
 */
@Service
public class EventPackageReset {

    private static final Logger log = LoggerFactory.getLogger(EventPackageReset.class);

    private final EventPackageService packages;
    private final JdbcClient jdbc;
    private final String file;

    public EventPackageReset(
            EventPackageService packages, JdbcClient jdbc, @Value("${brackety.reset-package}") String file) {
        this.packages = packages;
        this.jdbc = jdbc;
        this.file = file;
    }

    /** The package's file name, or empty on a server without one (it cannot be reset). */
    public Optional<String> packageName() {
        return file.isBlank()
                ? Optional.empty()
                : Optional.of(Path.of(file).getFileName().toString());
    }

    /** The new event's id. */
    @Transactional
    public UUID reset() {
        if (file.isBlank()) {
            throw new IllegalStateException("No event package to reset to");
        }
        byte[] content;
        try {
            content = Files.readAllBytes(Path.of(file));
        } catch (IOException e) {
            throw new UncheckedIOException(
                    "Cannot read the event package " + packageName().orElseThrow(), e);
        }
        // Every table of an event or a league references them (on delete cascade): truncate reaches them all.
        jdbc.sql("truncate table event, league cascade").update();
        var eventId = packages.load(content).eventId();
        log.warn("Event data wiped and package {} loaded again", packageName().orElseThrow());
        return eventId;
    }
}
