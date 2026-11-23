package dev.rgal.brackety.event.sport;

import dev.rgal.brackety.event.EventException;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** The sports to choose from (docs/producto/plantillas-deporte.md), each at its latest version. */
@Service
public class SportCatalog {

    private final SportVersionRepository versions;

    SportCatalog(SportVersionRepository versions) {
        this.versions = versions;
    }

    @Transactional(readOnly = true)
    public List<SportVersion> latest() {
        return versions.findLatest();
    }

    /** The latest version of the sport named {@code code}; refused when there is none. */
    @Transactional(readOnly = true)
    public SportVersion latest(String code) {
        return latest().stream()
                .filter(v -> v.code().equals(code))
                .findFirst()
                .orElseThrow(() -> EventException.invalid("Unknown sport: " + code));
    }

    /** As {@link #latest(String)}, and it must have a scoreboard to be played. */
    @Transactional(readOnly = true)
    public SportVersion playable(String code) {
        var sport = latest(code);
        if (!sport.rules().scoreboard()) {
            throw EventException.invalid("That discipline has no scoreboard yet.");
        }
        return sport;
    }
}
