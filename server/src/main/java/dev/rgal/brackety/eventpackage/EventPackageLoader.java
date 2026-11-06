package dev.rgal.brackety.eventpackage;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import org.springframework.beans.factory.SmartInitializingSingleton;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Loads BRACKETY_PACKAGE at startup, or stops the startup with the reason. It runs before the web server starts
 * (not on ApplicationReadyEvent), so the API never answers with the package half loaded or refused. The passwords of
 * the accounts it creates go to BRACKETY_PACKAGE_CREDENTIALS, never to the log.
 */
@Component
class EventPackageLoader implements SmartInitializingSingleton {

    static final String CREDENTIALS_HEADER = "usuario;rol;contraseña;tapices";

    private final EventPackageService packages;
    private final String file;
    private final String credentialsFile;

    EventPackageLoader(
            EventPackageService packages,
            @Value("${brackety.package}") String file,
            @Value("${brackety.package-credentials}") String credentialsFile) {
        this.packages = packages;
        this.file = file;
        this.credentialsFile = credentialsFile;
    }

    @Override
    public void afterSingletonsInstantiated() {
        if (file.isBlank()) {
            return;
        }
        if (credentialsFile.isBlank()) {
            throw new IllegalStateException(
                    "BRACKETY_PACKAGE_CREDENTIALS is required with BRACKETY_PACKAGE: the new staff passwords go there");
        }
        var path = Path.of(file);
        byte[] content;
        try {
            content = Files.readAllBytes(path);
        } catch (IOException e) {
            throw new IllegalStateException("Cannot read the event package " + path.getFileName(), e);
        }
        LoadedPackage loaded;
        try {
            loaded = packages.load(content);
        } catch (InvalidEventPackageException e) {
            throw new IllegalStateException(
                    "Event package " + path.getFileName() + " not loaded: " + e.getMessage(), e);
        }
        writeCredentials(loaded);
    }

    private void writeCredentials(LoadedPackage loaded) {
        var lines = new ArrayList<String>();
        lines.add(CREDENTIALS_HEADER);
        for (var account : loaded.newAccounts()) {
            lines.add(String.join(";", account.username(), account.roles(), account.password(), account.mats()));
        }
        var path = Path.of(credentialsFile);
        try {
            Files.write(path, lines, StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new IllegalStateException("Cannot write the staff passwords to " + path.getFileName(), e);
        }
    }
}
