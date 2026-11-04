package dev.rgal.brackety.auth.dto;

import dev.rgal.brackety.auth.account.ProfileType;
import jakarta.validation.Valid;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;

/**
 * What every new account gives, whatever the sign-in method. Organizers give their organization and declare they
 * are of legal age and represent it, instead of a birth date.
 */
public record RegistrationDetails(
        @NotNull ProfileType profile,
        @Past LocalDate birthDate,
        @Valid OrganizationRequest organization,
        Boolean representativeDeclaration,
        @NotBlank @Size(max = 32) String acceptedTermsVersion,
        @NotBlank @Size(max = 32) String acceptedPrivacyVersion,
        @NotNull @Pattern(regexp = "es|en") String locale) {

    public boolean isOrganizer() {
        return profile != null && profile.isOrganizer();
    }

    @AssertTrue(message = "organizers give organization and representativeDeclaration; the rest, birthDate")
    public boolean isProfileFieldsValid() {
        if (profile == null) {
            return true;
        }
        if (isOrganizer()) {
            return birthDate == null && organization != null && Boolean.TRUE.equals(representativeDeclaration);
        }
        return birthDate != null && organization == null && representativeDeclaration == null;
    }

    @Override
    public String toString() {
        return "RegistrationDetails[profile=" + profile + ", locale=" + locale + "]";
    }
}
