package dev.rgal.brackety.auth.admin;

import dev.rgal.brackety.auth.admin.AdminAuthService.AdminToken;
import dev.rgal.brackety.auth.admin.AdminLockService.LockResponse;
import dev.rgal.brackety.auth.admin.AdminOrganizerService.OrganizerResponse;
import dev.rgal.brackety.auth.dto.LoginRequest;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

// All of it behind Cloudflare Access (CloudflareAccessFilter); everything but the login needs the admin token.
@RestController
@RequestMapping(AdminController.BASE_PATH)
class AdminController {

    static final String BASE_PATH = "/api/v1/admin";

    private final AdminAuthService adminAuth;
    private final AdminLockService locks;
    private final AdminOrganizerService organizers;

    AdminController(AdminAuthService adminAuth, AdminLockService locks, AdminOrganizerService organizers) {
        this.adminAuth = adminAuth;
        this.locks = locks;
        this.organizers = organizers;
    }

    @PostMapping("/auth/login")
    AdminToken login(@Valid @RequestBody LoginRequest request, HttpServletRequest http) {
        return adminAuth.login(request.email(), request.password(), http.getRemoteAddr());
    }

    // No paging: a lock lasts 15 minutes, so there are only a few at a time.
    @GetMapping("/auth/locks")
    List<LockResponse> locks() {
        return locks.activeLocks();
    }

    @DeleteMapping("/auth/locks/{lockId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void revokeLock(@PathVariable String lockId) {
        locks.revoke(lockId);
    }

    @GetMapping("/organizers")
    List<OrganizerResponse> organizers(@RequestParam(required = false) Boolean validated) {
        return organizers.list(validated);
    }

    @PostMapping("/organizers/{accountId}/validate")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void validateOrganizer(@PathVariable UUID accountId) {
        organizers.validate(accountId);
    }
}
