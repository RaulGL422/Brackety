package dev.rgal.brackety.common;

import java.time.Clock;
import java.time.LocalDate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/info")
class InfoController {

    private final Clock clock;

    InfoController(Clock clock) {
        this.clock = clock;
    }

    @GetMapping
    InfoResponse info() {
        return new InfoResponse("brackety", LocalDate.now(clock));
    }

    record InfoResponse(String name, LocalDate today) {}
}
