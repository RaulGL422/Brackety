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

    InfoController(Clock clock, @Value("${brackety.version}") String version) {
        this.clock = clock;
        this.version = version;
    }

    @GetMapping
    InfoResponse info() {
        return new InfoResponse("brackety", version, LocalDate.now(clock));
    }

    record InfoResponse(String name, String version, LocalDate today) {}
}
