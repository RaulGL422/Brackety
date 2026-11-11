package dev.rgal.brackety.scoreboard;

public enum MatchEventType {
    START,
    STOP,
    POINT,
    /** Takes one point off a fighter, never below 0: the referee's manual correction. */
    POINT_REMOVED,
    WARNING,
    /** Only for fighters aged 4 to 7. */
    ONE_HAND_WARNING,
    DISQUALIFICATION,
    /** Adds (or, negative, takes) time on the stopped clock; the event carries the delta. */
    CLOCK_ADJUST,
    /** Cancels the last point, point removed, warning, disqualification or clock adjustment still in force. */
    UNDO,
    FINISH
}
