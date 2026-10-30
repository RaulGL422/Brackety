package dev.rgal.brackety.auth.dto;

import dev.rgal.brackety.auth.account.ProfileType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;

/** What every new account gives, whatever the sign-in method. */
public record RegistrationDetails(
        @NotNull @Past LocalDate birthDate,
        @NotNull ProfileType profile,
        @NotBlank @Size(max = 32) String acceptedTermsVersion,
        @NotBlank @Size(max = 32) String acceptedPrivacyVersion,
        @NotNull @Pattern(regexp = "es|en") String locale) {

    @Override
    public String toString() {
        return "RegistrationDetails[profile=" + profile + ", locale=" + locale + "]";
    }
}
