package dev.rgal.brackety.participant.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.math.BigDecimal;

/** Measured on the day of the event; null leaves it unmeasured. */
public record MeasuresRequest(
        @Min(50) @Max(250) Integer heightCm,

        @DecimalMin("10.0") @DecimalMax("250.0") @Digits(integer = 3, fraction = 1)
        BigDecimal weightKg) {}
