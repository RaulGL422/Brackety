package dev.rgal.brackety.event.dto;

import dev.rgal.brackety.event.Event;
import dev.rgal.brackety.event.MeasureRequirement;

/** {@code weight} and {@code height}: the event's own choice, null when it follows its sport ({@code sport*}). */
public record MeasureRules(
        MeasureRequirement weight,
        MeasureRequirement height,
        MeasureRequirement sportWeight,
        MeasureRequirement sportHeight) {

    public static MeasureRules of(Event event) {
        return new MeasureRules(
                event.getOwnWeightRequirement(),
                event.getOwnHeightRequirement(),
                event.getDiscipline().weight(),
                event.getDiscipline().height());
    }
}
