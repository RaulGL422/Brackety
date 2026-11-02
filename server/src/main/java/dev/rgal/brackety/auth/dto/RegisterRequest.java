package dev.rgal.brackety.auth.dto;

import dev.rgal.brackety.auth.account.ProfileType;
import jakarta.validation.Valid;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;

/** The {@link RegistrationDetails} plus the password credentials. */
public record RegisterRequest(
        @NotBlank @Email @Size(max = 254) String email,
        @NotNull @Size(min = 10, max = 128) String password,
        @NotNull ProfileType profile,
        @Past LocalDate birthDate,
        @Valid OrganizationRequest organization,
        Boolean representativeDeclaration,
        @NotBlank @Size(max = 32) String acceptedTermsVersion,
        @NotBlank @Size(max = 32) String acceptedPrivacyVersion,
        @NotNull @Pattern(regexp = "es|en") String locale) {

    public RegistrationDetails details() {
        return new RegistrationDetails(
                profile,
                birthDate,
                organization,
                representativeDeclaration,
                acceptedTermsVersion,
                acceptedPrivacyVersion,
                locale);
    }

    @AssertTrue(message = "organizers give organization and representativeDeclaration; the rest, birthDate")
    public boolean isProfileFieldsValid() {
        return details().isProfileFieldsValid();
    }

    @Override
    public String toString() {
        return "RegisterRequest[profile=" + profile + ", locale=" + locale + "]";
    }
}
