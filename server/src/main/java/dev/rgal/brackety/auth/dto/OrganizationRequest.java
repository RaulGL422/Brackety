package dev.rgal.brackety.auth.dto;

import dev.rgal.brackety.auth.account.Cif;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** The organization an organizer represents. The CIF is checked by the service, to answer INVALID_TAX_ID. */
public record OrganizationRequest(
        @NotNull @Size(min = 2, max = 200) String name,
        @NotNull String taxId) {

    public OrganizationRequest {
        name = name == null ? null : name.strip();
        taxId = Cif.normalize(taxId);
    }
}
