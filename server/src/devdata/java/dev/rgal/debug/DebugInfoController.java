package dev.rgal.debug;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/** For the "DEBUG" banner of the app, also before signing in: which scenario and which day. No data of anyone. */
@RestController
class DebugInfoController {

    private final DebugData data;

    DebugInfoController(DebugData data) {
        this.data = data;
    }

    @GetMapping("/api/v1/debug")
    DebugData.Status status() {
        return data.status();
    }
}
