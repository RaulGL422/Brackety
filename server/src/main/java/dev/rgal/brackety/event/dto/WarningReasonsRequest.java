package dev.rgal.brackety.event.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;

/** Null follows the sport; an empty list leaves only "Otro" (a reason typed by hand). */
public record WarningReasonsRequest(@Size(max = 20) List<@NotBlank @Size(max = 60) String> reasons) {}
