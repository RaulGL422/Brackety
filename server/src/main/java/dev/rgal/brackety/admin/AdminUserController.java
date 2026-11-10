package dev.rgal.brackety.admin;

import dev.rgal.brackety.admin.dto.AdminEventDtos.ReasonRequest;
import dev.rgal.brackety.admin.dto.AdminUserDtos.UserDetail;
import dev.rgal.brackety.admin.dto.AdminUserDtos.UserPage;
import dev.rgal.brackety.auth.dto.DeletionResponse;
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
@RequestMapping("/api/v1/admin/users")
class AdminUserController {

    private final AdminUserService users;

    AdminUserController(AdminUserService users) {
        this.users = users;
    }

    @GetMapping
    UserPage list(
            @RequestParam(defaultValue = "") String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return users.list(q, page, size);
    }

    @GetMapping("/{accountId}")
    UserDetail detail(@PathVariable UUID accountId) {
        return users.detail(accountId);
    }

    @PostMapping("/{accountId}/suspend")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void suspend(@PathVariable UUID accountId, @Valid @RequestBody ReasonRequest request) {
        users.suspend(accountId, request.reason());
    }

    @PostMapping("/{accountId}/unsuspend")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void unsuspend(@PathVariable UUID accountId, @Valid @RequestBody ReasonRequest request) {
        users.unsuspend(accountId, request.reason());
    }

    @PostMapping("/{accountId}/delete")
    DeletionResponse delete(@PathVariable UUID accountId, @Valid @RequestBody ReasonRequest request) {
        return new DeletionResponse(users.delete(accountId, request.reason()));
    }
}
