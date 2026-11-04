package dev.rgal.brackety.event;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import dev.rgal.brackety.event.dto.CategoriesRequest;
import dev.rgal.brackety.event.dto.EventSettingsRequest;
import dev.rgal.brackety.event.dto.EventSettingsResponse;
import dev.rgal.brackety.event.dto.EventSettingsResponse.CategoryResponse;
import dev.rgal.brackety.event.dto.MyEventResponse;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/events")
@RequiresVerifiedEmail
class EventController {

    private final EventService events;
    private final EventCategoryService categories;

    EventController(EventService events, EventCategoryService categories) {
        this.events = events;
        this.categories = categories;
    }

    @GetMapping
    List<MyEventResponse> myEvents(@AuthenticationPrincipal Jwt jwt) {
        return events.myEvents(CurrentAccount.id(jwt));
    }

    @GetMapping("/{eventId}/settings")
    EventSettingsResponse settings(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return events.settings(eventId, CurrentAccount.id(jwt));
    }

    @PutMapping("/{eventId}/settings")
    EventSettingsResponse updateSettings(
            @PathVariable UUID eventId,
            @Valid @RequestBody EventSettingsRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        return events.updateSettings(eventId, CurrentAccount.id(jwt), request);
    }

    @PutMapping("/{eventId}/categories")
    List<CategoryResponse> updateCategories(
            @PathVariable UUID eventId,
            @Valid @RequestBody CategoriesRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        return categories.update(eventId, CurrentAccount.id(jwt), request);
    }
}
