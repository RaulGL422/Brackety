package dev.rgal.brackety.common;

import java.time.Clock;
import java.time.LocalDate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/info")
class InfoController {

    private final Clock clock;
    private final String version;
    private final String commit;

    InfoController(
            Clock clock, @Value("${brackety.version}") String version, @Value("${brackety.commit}") String commit) {
        this.clock = clock;
        this.version = version;
        this.commit = commit;
    }

    @GetMapping
    InfoResponse info() {
        return new InfoResponse("brackety", version, commit, LocalDate.now(clock));
    }

    /** {@code version} and {@code commit}: what the apps compare with their own build to offer the update. */
    record InfoResponse(String name, String version, String commit, LocalDate today) {}
}
