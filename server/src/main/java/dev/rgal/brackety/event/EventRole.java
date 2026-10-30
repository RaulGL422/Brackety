package dev.rgal.brackety.event;

public enum EventRole {
    /** Organizer: settings, registrations, live results and export. */
    CLUB,
    /** Helper who builds the groups and sends them to a mat. */
    GROUPER,
    /** Runs the scoreboard of the mat assigned to them. */
    REFEREE
}
