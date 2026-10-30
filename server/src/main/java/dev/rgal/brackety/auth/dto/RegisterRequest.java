package dev.rgal.brackety.auth.dto;

import dev.rgal.brackety.auth.account.ProfileType;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;

public record RegisterRequest(
        @NotBlank @Email @Size(max = 254) String email,
        @NotNull @Size(min = 10, max = 128) String password,
        @NotNull @Past LocalDate birthDate,
        @NotNull ProfileType profile,
        @NotBlank @Size(max = 32) String acceptedTermsVersion,
        @NotBlank @Size(max = 32) String acceptedPrivacyVersion,
        @NotNull @Pattern(regexp = "es|en") String locale) {

    @Override
    public String toString() {
        return "RegisterRequest[profile=" + profile + ", locale=" + locale + "]";
    }
}
