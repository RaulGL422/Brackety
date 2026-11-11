package dev.rgal.brackety.event;

import dev.rgal.brackety.event.dto.EventSettingsResponse.OrganizationResponse;
import dev.rgal.brackety.event.dto.OrganizationRequest;
import dev.rgal.brackety.event.dto.OrganizationsRequest;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** The club lists the organizations (clubs) taking part; each participant may belong to one. */
@Service
class EventOrganizationService {

    private final EventOrganizationRepository organizations;
    private final EventAccess access;

    EventOrganizationService(EventOrganizationRepository organizations, EventAccess access) {
        this.organizations = organizations;
        this.access = access;
    }

    @Transactional
    List<OrganizationResponse> update(UUID eventId, UUID accountId, OrganizationsRequest request) {
        access.require(eventId, accountId, EventRole.CLUB);
        var requested = request.organizations();
        var names = new HashSet<String>();
        for (var o : requested) {
            if (!names.add(o.name().strip().toLowerCase(Locale.ROOT))) {
                throw EventException.invalid("Two organizations have the same name.");
            }
        }
        var current = organizations.findByEventIdOrderByName(eventId).stream()
                .collect(Collectors.toMap(EventOrganization::getId, Function.identity()));
        var kept = requested.stream()
                .map(OrganizationRequest::id)
                .filter(Objects::nonNull)
                .toList();
        if (!current.keySet().containsAll(kept) || new HashSet<>(kept).size() != kept.size()) {
            throw EventException.invalid("Unknown organization.");
        }
        var removed = current.keySet().stream().filter(id -> !kept.contains(id)).toList();
        if (removed.stream().anyMatch(new HashSet<>(organizations.findInUse(eventId))::contains)) {
            throw EventException.conflict("An organization with participants cannot be removed.");
        }
        organizations.deleteAllById(removed);
        organizations.flush();
        for (var o : requested) {
            if (o.id() == null) {
                organizations.save(new EventOrganization(eventId, o.name().strip(), shortName(o.shortName())));
            } else {
                current.get(o.id()).update(o.name().strip(), shortName(o.shortName()));
            }
        }
        organizations.flush();
        return list(organizations, eventId);
    }

    static List<OrganizationResponse> list(EventOrganizationRepository organizations, UUID eventId) {
        return organizations.findByEventIdOrderByName(eventId).stream()
                .map(OrganizationResponse::of)
                .toList();
    }

    private static String shortName(String shortName) {
        return shortName == null || shortName.isBlank() ? null : shortName.strip();
    }
}
