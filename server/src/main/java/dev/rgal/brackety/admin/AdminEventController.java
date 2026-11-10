package dev.rgal.brackety.admin;

import dev.rgal.brackety.admin.dto.AdminEventDtos.Cleared;
import dev.rgal.brackety.admin.dto.AdminEventDtos.EventDetail;
import dev.rgal.brackety.admin.dto.AdminEventDtos.EventPage;
import dev.rgal.brackety.admin.dto.AdminEventDtos.ReasonRequest;
import dev.rgal.brackety.admin.dto.AdminMetrics;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

// Under /api/v1/admin: Cloudflare Access and the superadmin token, as the rest of the superadmin API.
@RestController
@RequestMapping("/api/v1/admin")
class AdminEventController {

    private final AdminEventService events;
    private final AdminMetricsService metrics;

    AdminEventController(AdminEventService events, AdminMetricsService metrics) {
        this.events = events;
        this.metrics = metrics;
    }

    @GetMapping("/metrics")
    AdminMetrics metrics() {
        return metrics.read();
    }

    @GetMapping("/events")
    EventPage list(@RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return events.list(page, size);
    }

    @GetMapping("/events/{eventId}")
    EventDetail detail(@PathVariable UUID eventId) {
        return events.detail(eventId);
    }

    @PostMapping("/matches/{matchId}/reset")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void resetMatch(@PathVariable UUID matchId, @Valid @RequestBody ReasonRequest request) {
        events.resetMatch(matchId, request.reason());
    }

    @PostMapping("/groups/{groupId}/dissolve")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void dissolveGroup(@PathVariable UUID groupId, @Valid @RequestBody ReasonRequest request) {
        events.dissolveGroup(groupId, request.reason());
    }

    @PostMapping("/events/{eventId}/clear-competition")
    Cleared clearCompetition(@PathVariable UUID eventId, @Valid @RequestBody ReasonRequest request) {
        return events.clearCompetition(eventId, request.reason());
    }
}
