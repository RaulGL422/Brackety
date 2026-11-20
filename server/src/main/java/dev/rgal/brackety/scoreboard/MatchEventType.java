package dev.rgal.brackety.scoreboard;

public enum MatchEventType {
    START,
    STOP,
    POINT,
    /** Takes points off a fighter (its value, 1 by default), never below 0: the referee's manual correction. */
    POINT_REMOVED,
    WARNING,
    /** Only for fighters aged 4 to 7. */
    ONE_HAND_WARNING,
    DISQUALIFICATION,
    /** Adds (or, negative, takes) time on the stopped clock; the event carries the delta. */
    CLOCK_ADJUST,
    /** Cancels the last {@link #undoable()} action still in force. */
    UNDO,
    FINISH,
    /**
     * A match started by mistake goes back to pending, all at 0; the trail stays. Only started and not finished,
     * with a reason.
     */
    CANCEL,
    /** A finished match opens again to correct it, with what it had; with a reason and nothing else on the mat. */
    REOPEN,
    /** The side that made the other give up; ends the match. Only in sports with submissions (grappling). */
    SUBMISSION,
    /** The side that won the extra time of a match tied after every tiebreaker (grappling). */
    EXTRA_TIME;

    /** What an UNDO can take back: the referee's scoring actions, not the clock's start and stop nor the outcome. */
    boolean undoable() {
        return switch (this) {
            case POINT,
                    POINT_REMOVED,
                    CLOCK_ADJUST,
                    WARNING,
                    ONE_HAND_WARNING,
                    DISQUALIFICATION,
                    SUBMISSION,
                    EXTRA_TIME -> true;
            case START, STOP, FINISH, CANCEL, REOPEN, UNDO -> false;
        };
    }
}
