package dev.rgal.brackety.event.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

/** The event's whole category list: categories left out are removed. */
public record CategoriesRequest(@NotEmpty @Size(max = 30) List<@Valid @NotNull CategoryRequest> categories) {}
