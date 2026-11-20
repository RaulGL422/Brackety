package dev.rgal.brackety.event;

import java.util.EnumSet;
import java.util.Set;

/** What a helper or referee may do in an event (F1-7 C); the club may do everything. */
public enum EventPermission {
    /** Sees categories, groups, mats and matches without changing anything. */
    VIEW,
    GROUPS,
    TEAMS,
    MEASURES,
    OWN_MAT,
    PHASE,
    CONTROL,
    REVIEWS,
    DEVICE_IMPORT,
    PARTICIPANTS;

    /** Sees every mat and match: the control panel, the reviews or plain viewing. */
    public static boolean watchesMats(Set<EventPermission> granted) {
        return granted.contains(CONTROL) || granted.contains(REVIEWS) || granted.contains(VIEW);
    }

    /** Until the club chooses: a helper builds groups, teams and measures; a referee runs their mat. */
    public static Set<EventPermission> defaults(Set<EventRole> roles) {
        var permissions = EnumSet.noneOf(EventPermission.class);
        if (roles.contains(EventRole.CLUB)) {
            return EnumSet.allOf(EventPermission.class);
        }
        if (roles.contains(EventRole.GROUPER)) {
            permissions.addAll(EnumSet.of(GROUPS, TEAMS, MEASURES));
        }
        if (roles.contains(EventRole.REFEREE)) {
            permissions.add(OWN_MAT);
        }
        return permissions;
    }
}
