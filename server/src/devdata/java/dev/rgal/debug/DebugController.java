package dev.rgal.debug;

import dev.rgal.brackety.event.EventException;
import java.time.LocalDate;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Only in the debug image (docs/modulos/entornos.md): under the superadmin's path, so its token and Cloudflare
 * Access guard it; in production these paths do not exist (404).
 */
@RestController
@RequestMapping("/api/v1/admin/dev")
class DebugController {

    /** {@code confirm}: the scenario's name typed again, as everything is wiped. {@code today}: null, the real day. */
    record LoadRequest(String confirm, LocalDate today) {}

    /** Null goes back to the real day. */
    record ClockRequest(LocalDate today) {}

    private final DebugData data;

    DebugController(DebugData data) {
        this.data = data;
    }

    @GetMapping
    DebugData.Status status() {
        return data.status();
    }

    @GetMapping("/scenarios")
    List<DebugData.ScenarioInfo> scenarios() {
        return data.scenarios();
    }

    @PostMapping("/scenarios/{name}/load")
    DebugData.Status load(@PathVariable String name, @RequestBody LoadRequest request) {
        var scenario = data.find(name).orElseThrow(EventException::notFound);
        if (!name.equals(request.confirm())) {
            throw EventException.invalid("Type the scenario's name to confirm: everything is wiped.");
        }
        return data.load(scenario, request.today());
    }

    @PutMapping("/clock")
    DebugData.Status clock(@RequestBody ClockRequest request) {
        return data.moveClock(request.today());
    }
}
