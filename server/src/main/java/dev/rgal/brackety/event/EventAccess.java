package dev.rgal.brackety.event;

import java.util.Arrays;
import java.util.EnumSet;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;

/** Every event endpoint checks the caller's role in that event here, on the server. */
@Service
public class EventAccess {

    private final EventStaffRepository staff;

    EventAccess(EventStaffRepository staff) {
        this.staff = staff;
    }

    public Set<EventRole> roles(UUID eventId, UUID accountId) {
        return staff.findByEventIdAndAccountId(eventId, accountId).stream()
                .map(EventStaff::getRole)
                .collect(Collectors.toCollection(() -> EnumSet.noneOf(EventRole.class)));
    }

    public void require(UUID eventId, UUID accountId, EventRole... allowed) {
        var roles = roles(eventId, accountId);
        if (roles.isEmpty()) {
            throw EventException.notFound();
        }
        if (Arrays.stream(allowed).noneMatch(roles::contains)) {
            throw EventException.forbidden();
        }
    }
}
