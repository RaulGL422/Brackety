package dev.rgal.brackety.auth.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

/** The legal texts the person read and accepted, with the version they read; each must be the current one. */
public record ConsentRequest(@NotEmpty @Size(max = 4) List<@Valid @NotNull Accepted> accepted) {

    /** {@code document}: terms or privacy. */
    public record Accepted(
            @NotBlank @Size(max = 16) String document,
            @NotBlank @Size(max = 32) String version) {}
}
