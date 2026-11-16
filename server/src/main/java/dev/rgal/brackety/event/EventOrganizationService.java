package dev.rgal.brackety.event;

import dev.rgal.brackety.event.dto.EventSettingsResponse.OrganizationResponse;
import dev.rgal.brackety.event.dto.OrganizationRequest;
import dev.rgal.brackety.event.dto.OrganizationsRequest;
import java.time.Clock;
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
    private final OrganizationRepository clubs;
    private final EventRepository events;
    private final EventAccess access;
    private final Clock clock;

    EventOrganizationService(
            EventOrganizationRepository organizations,
            OrganizationRepository clubs,
            EventRepository events,
            EventAccess access,
            Clock clock) {
        this.organizations = organizations;
        this.clubs = clubs;
        this.events = events;
        this.access = access;
        this.clock = clock;
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
        var owner = events.findById(eventId).orElseThrow().getOwnerAccountId();
        for (var o : requested) {
            var name = o.name().strip();
            var shortName = shortName(o.shortName());
            var link = o.id() == null ? null : current.get(o.id());
            var same = clubs.findByOwnerAccountIdAndNameIgnoreCase(owner, name);
            if (link != null && (same.isEmpty() || same.get().equals(link.getOrganization()))) {
                // A new name for the same club: it changes in every event the club is in.
                link.getOrganization().update(name, shortName);
                continue;
            }
            var club = same.orElseGet(() -> clubs.named(owner, name, shortName, clock.instant()));
            club.update(name, shortName);
            if (link == null) {
                organizations.save(new EventOrganization(eventId, club));
            } else {
                // The name of another club of the owner: this event now links that one.
                link.link(club);
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
