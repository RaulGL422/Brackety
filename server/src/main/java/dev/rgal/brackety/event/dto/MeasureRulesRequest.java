package dev.rgal.brackety.event.dto;

import dev.rgal.brackety.event.MeasureRequirement;

/** Null follows the sport. */
public record MeasureRulesRequest(MeasureRequirement weight, MeasureRequirement height) {}
