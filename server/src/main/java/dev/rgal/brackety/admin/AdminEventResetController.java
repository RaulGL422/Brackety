package dev.rgal.brackety.admin;

import dev.rgal.brackety.admin.dto.AdminEventDtos.ReasonRequest;
import dev.rgal.brackety.auth.admin.AdminAuditLog;
import dev.rgal.brackety.event.EventException;
import dev.rgal.brackety.eventpackage.EventPackageReset;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** On the hall laptop, the superadmin starts the event again from its package (EventPackageReset). */
@RestController
@RequestMapping("/api/v1/admin/event-reset")
class AdminEventResetController {

    /** {@code packageName}: null on a server without a package, where there is nothing to reset to. */
    record ResetInfo(String packageName) {}

    record ResetDone(UUID eventId) {}

    private final EventPackageReset reset;
    private final AdminAuditLog audit;

    AdminEventResetController(EventPackageReset reset, AdminAuditLog audit) {
        this.reset = reset;
        this.audit = audit;
    }

    @GetMapping
    ResetInfo info() {
        return new ResetInfo(reset.packageName().orElse(null));
    }

    @PostMapping
    ResetDone reset(@Valid @RequestBody ReasonRequest request) {
        var name = reset.packageName().orElseThrow(EventException::notFound);
        var eventId = reset.reset();
        audit.control(
                eventId,
                "event reset from package " + name + ": " + request.reason().strip());
        return new ResetDone(eventId);
    }
}
