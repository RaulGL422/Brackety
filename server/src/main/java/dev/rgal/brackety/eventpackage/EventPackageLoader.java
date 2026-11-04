package dev.rgal.brackety.eventpackage;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.springframework.beans.factory.SmartInitializingSingleton;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Loads BRACKETY_PACKAGE at startup, or stops the startup with the reason. It runs before the web server starts
 * (not on ApplicationReadyEvent), so the API never answers with the package half loaded or refused.
 */
@Component
class EventPackageLoader implements SmartInitializingSingleton {

    private final EventPackageService packages;
    private final String file;

    EventPackageLoader(EventPackageService packages, @Value("${brackety.package}") String file) {
        this.packages = packages;
        this.file = file;
    }

    @Override
    public void afterSingletonsInstantiated() {
        if (file.isBlank()) {
            return;
        }
        var path = Path.of(file);
        byte[] content;
        try {
            content = Files.readAllBytes(path);
        } catch (IOException e) {
            throw new IllegalStateException("Cannot read the event package " + path.getFileName(), e);
        }
        try {
            packages.load(content);
        } catch (InvalidEventPackageException e) {
            throw new IllegalStateException(
                    "Event package " + path.getFileName() + " not loaded: " + e.getMessage(), e);
        }
    }
}
