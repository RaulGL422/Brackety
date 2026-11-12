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
    FINISH,
    /**
     * A match started by mistake goes back to pending, all at 0; the trail stays. Only started and not finished,
     * with a reason.
     */
    CANCEL,
    /** A finished match opens again to correct it, with what it had; with a reason and nothing else on the mat. */
    REOPEN
}
