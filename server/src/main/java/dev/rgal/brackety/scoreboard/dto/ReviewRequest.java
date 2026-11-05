package dev.rgal.brackety.scoreboard.dto;

import jakarta.validation.constraints.NotNull;

/** The club's decision on the actions a device sent that clashed. */
public record ReviewRequest(@NotNull Action action) {

    public enum Action {
        APPLY,
        DISCARD
    }
}
