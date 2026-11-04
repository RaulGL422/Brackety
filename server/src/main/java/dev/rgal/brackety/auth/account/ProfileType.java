package dev.rgal.brackety.auth.account;

public enum ProfileType {
    CLUB,
    EXTERNAL_ENTITY,
    HELPER,
    EXTERNAL,
    STUDENT;

    /** Organizers hold events and the superadmin validates them. */
    public boolean isOrganizer() {
        return this == CLUB || this == EXTERNAL_ENTITY;
    }
}
