package dev.rgal.brackety.grouping;

import dev.rgal.brackety.auth.RequiresVerifiedEmail;
import dev.rgal.brackety.common.CurrentAccount;
import dev.rgal.brackety.grouping.dto.CategoryParticipant;
import dev.rgal.brackety.grouping.dto.CategorySummary;
import dev.rgal.brackety.grouping.dto.CreateGroupsRequest;
import dev.rgal.brackety.grouping.dto.CreateGroupsResponse;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/events/{eventId}")
@RequiresVerifiedEmail
class GroupController {

    private final GroupService groups;

    GroupController(GroupService groups) {
        this.groups = groups;
    }

    @GetMapping("/categories")
    List<CategorySummary> categories(@PathVariable UUID eventId, @AuthenticationPrincipal Jwt jwt) {
        return groups.categories(eventId, CurrentAccount.id(jwt));
    }

    @GetMapping("/categories/{categoryId}/participants")
    List<CategoryParticipant> categoryParticipants(
            @PathVariable UUID eventId, @PathVariable UUID categoryId, @AuthenticationPrincipal Jwt jwt) {
        return groups.categoryParticipants(eventId, categoryId, CurrentAccount.id(jwt));
    }

    @PostMapping("/groups")
    @ResponseStatus(HttpStatus.CREATED)
    CreateGroupsResponse create(
            @PathVariable UUID eventId,
            @Valid @RequestBody CreateGroupsRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        return groups.create(eventId, CurrentAccount.id(jwt), request);
    }
}
