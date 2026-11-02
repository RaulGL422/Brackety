package dev.rgal.brackety.event;

import dev.rgal.brackety.event.EventCategory.Format;
import dev.rgal.brackety.event.dto.CategoriesRequest;
import dev.rgal.brackety.event.dto.CategoryRequest;
import dev.rgal.brackety.event.dto.EventSettingsResponse.CategoryResponse;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** The club sets the event's categories: age bands and whether they compete individually or as teams. */
@Service
class EventCategoryService {

    private final EventCategoryRepository categories;
    private final EventService events;
    private final EventAccess access;

    EventCategoryService(EventCategoryRepository categories, EventService events, EventAccess access) {
        this.categories = categories;
        this.events = events;
        this.access = access;
    }

    @Transactional
    List<CategoryResponse> update(UUID eventId, UUID accountId, CategoriesRequest request) {
        access.require(eventId, accountId, EventRole.CLUB);
        // Same lock as group and team creation, so none is made for a category being changed.
        events.lock(eventId);
        var requested = request.categories();
        requested.forEach(EventCategoryService::check);
        checkNoOverlap(requested);

        var current = categories.findByEventIdOrderByMinAge(eventId).stream()
                .collect(Collectors.toMap(EventCategory::getId, Function.identity()));
        var inUse = new HashSet<>(categories.findInUse(eventId));
        var kept = requested.stream()
                .map(CategoryRequest::id)
                .filter(Objects::nonNull)
                .toList();
        if (!current.keySet().containsAll(kept) || new HashSet<>(kept).size() != kept.size()) {
            throw EventException.invalid("Unknown category.");
        }
        var removed = current.keySet().stream().filter(id -> !kept.contains(id)).toList();
        if (removed.stream().anyMatch(inUse::contains)) {
            throw EventException.conflict("A category with groups or teams cannot be removed.");
        }
        categories.deleteAllById(removed);
        for (var c : requested) {
            var teamSize = c.format() == Format.TEAM ? c.teamSize() : null;
            if (c.id() == null) {
                categories.save(new EventCategory(eventId, c.name().strip(), c.minAge(), c.maxAge(), teamSize));
                continue;
            }
            var category = current.get(c.id());
            if (inUse.contains(c.id()) && changesWhoFights(category, c, teamSize)) {
                throw EventException.conflict("A category with groups or teams only changes its name.");
            }
            category.update(c.name().strip(), c.minAge(), c.maxAge(), teamSize);
        }
        return categories.findByEventIdOrderByMinAge(eventId).stream()
                .map(CategoryResponse::of)
                .toList();
    }

    private static void check(CategoryRequest c) {
        if (c.minAge() > c.maxAge()) {
            throw EventException.invalid("The minimum age is above the maximum.");
        }
        if (c.format() == Format.TEAM && c.teamSize() == null) {
            throw EventException.invalid("A team category needs a team size.");
        }
        // The round robin and the ghost rules only exist for groups of 4.
        if (c.groupSize() != EventCategory.GROUP_SIZE) {
            throw EventException.invalid("Groups are of " + EventCategory.GROUP_SIZE + " for now.");
        }
    }

    // Each participant's age must fall in one category only.
    private static void checkNoOverlap(List<CategoryRequest> requested) {
        var sorted = requested.stream()
                .sorted(Comparator.comparingInt(CategoryRequest::minAge))
                .toList();
        for (int i = 1; i < sorted.size(); i++) {
            if (sorted.get(i).minAge() <= sorted.get(i - 1).maxAge()) {
                throw EventException.invalid("Two categories share ages.");
            }
        }
    }

    private static boolean changesWhoFights(EventCategory category, CategoryRequest c, Integer teamSize) {
        return category.getMinAge() != c.minAge()
                || category.getMaxAge() != c.maxAge()
                || !Objects.equals(category.getTeamSize(), teamSize);
    }
}
