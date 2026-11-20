package dev.rgal.brackety.scoreboard;

/** How a match ended; stored by name in {@code fight_match.end_reason}. */
enum EndReason {
    /** Reached the points limit (tambo). */
    POINTS,
    /** Reached the points difference (grappling's technical superiority). */
    SUPERIORITY,
    TIME,
    DISQUALIFICATION,
    /** The last warning a sport allows (grappling: the 4th). */
    WARNINGS,
    SUBMISSION,
    EXTRA_TIME
}
