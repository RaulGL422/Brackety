package dev.rgal.brackety.event.dto;

import dev.rgal.brackety.event.Event;
import java.util.List;

/** {@code own}: the event's list, null when it follows its sport's ({@code sport}). */
public record WarningReasons(List<String> own, List<String> sport) {

    public static WarningReasons of(Event event) {
        return new WarningReasons(
                event.getOwnWarningReasons(), event.getSport().rules().warningReasons());
    }
}
