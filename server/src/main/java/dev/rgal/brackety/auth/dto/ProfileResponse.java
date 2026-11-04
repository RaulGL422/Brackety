package dev.rgal.brackety.auth.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import dev.rgal.brackety.auth.account.Profile;
import dev.rgal.brackety.auth.account.ProfileType;

/** {@code validated} by the superadmin; it and the organization only mean something for organizers. */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ProfileResponse(ProfileType type, boolean validated, String organizationName, String taxId) {

    public static ProfileResponse of(Profile profile) {
        return new ProfileResponse(
                profile.getType(), profile.isValidated(), profile.getOrganizationName(), profile.getTaxId());
    }
}
