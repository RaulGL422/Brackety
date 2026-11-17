package dev.rgal.brackety.event;

/**
 * Whether an event asks for a measure (weight, height) of each participant (docs/producto/feedback-f1.md, F2-1).
 * Required: nobody goes into a group or team without it. Optional: the grouping screen says who lacks it. Off: not
 * asked.
 */
public enum MeasureRequirement {
    OFF,
    OPTIONAL,
    REQUIRED
}
