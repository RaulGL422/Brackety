package dev.rgal.brackety.league;

import dev.rgal.brackety.event.EventAccess;
import dev.rgal.brackety.event.EventCategoryRepository;
import dev.rgal.brackety.event.EventOrganization;
import dev.rgal.brackety.event.EventOrganizationRepository;
import dev.rgal.brackety.event.EventStaff;
import dev.rgal.brackety.event.EventStaffRepository;
import dev.rgal.brackety.event.Mat;
import dev.rgal.brackety.event.MatRepository;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/**
 * What a new phase inherits from the one it comes from: the staff who last and their permissions, the mats (with
 * their referee if they stay), the categories and the clubs. The entries do not pass: each person re-enrols.
 */
@Component
class PhaseCarryOver {

    private final EventStaffRepository staff;
    private final EventAccess access;
    private final MatRepository mats;
    private final EventCategoryRepository categories;
    private final EventOrganizationRepository organizations;

    PhaseCarryOver(
            EventStaffRepository staff,
            EventAccess access,
            MatRepository mats,
            EventCategoryRepository categories,
            EventOrganizationRepository organizations) {
        this.staff = staff;
        this.access = access;
        this.mats = mats;
        this.categories = categories;
        this.organizations = organizations;
    }

    void copy(UUID from, UUID to) {
        var lasting = staff.findLastingByEventId(from);
        for (var member : lasting) {
            staff.save(new EventStaff(to, member.getAccountId(), member.getRole()));
        }
        staff.flush();
        access.copyPermissions(from, to);
        var kept = lasting.stream().map(EventStaff::getAccountId).collect(Collectors.toSet());
        for (var mat : mats.findByEventIdOrderByNumber(from)) {
            var referee = kept.contains(mat.getRefereeAccountId()) ? mat.getRefereeAccountId() : null;
            mats.save(new Mat(to, mat.getNumber(), referee));
        }
        for (var c : categories.findByEventIdOrderByMinAge(from)) {
            categories.save(c.copyFor(to));
        }
        for (var o : organizations.findByEventIdOrderByName(from)) {
            organizations.save(new EventOrganization(to, o.getOrganization()));
        }
    }
}
