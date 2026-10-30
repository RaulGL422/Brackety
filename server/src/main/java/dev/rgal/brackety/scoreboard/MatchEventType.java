package dev.rgal.brackety.scoreboard;

public enum MatchEventType {
    START,
    STOP,
    POINT,
    WARNING,
    /** Only for fighters aged 4 to 7. */
    ONE_HAND_WARNING,
    DISQUALIFICATION,
    /** Cancels the last point, warning or disqualification still in force. */
    UNDO,
    FINISH
}
